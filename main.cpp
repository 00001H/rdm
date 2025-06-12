#include<cppp/int-width.hpp>
#include<iostream>
#include<cstddef>
#include<cstdint>
#include<utility>
#include<cstring>
#include<vector>
#include<array>
#include<tuple>
constexpr static std::size_t NREGS = 0x80uz;
using reg_state = std::array<std::uint64_t,NREGS>;
using reg = cppp::unsigned_limits::fastest_fit_t<NREGS>;
class RegisterRange{
    reg _begin;
    reg _size;
    bool _has_shadow;
    public:
        enum RangeMatch{
            OUTSIDE,INSIDE,SHADOW
        };
        struct MatchResult{
            RangeMatch status;
            reg offset;
        };
        reg begin() const{
            return _begin;
        }
        reg operator[](reg offs) const{
            return _begin+offs;
        }
        reg size() const{
            return _size;
        }
        reg shadow(reg offs) const{
            return _begin+_size+offs;
        }
        bool has_shadow() const{
            return _has_shadow;
        }
        constexpr RegisterRange(reg b,reg l,bool s) : _begin(b), _size(l), _has_shadow(s){}
        constexpr MatchResult test(reg r) const{
            reg offset=r-_begin;
            if(offset < _size){
                return {.status=INSIDE,.offset=offset};
            }else if(_has_shadow && (offset -= _size) < _size){
                return {.status=SHADOW,.offset=offset};
            }
            return {.status=OUTSIDE,.offset=0};
        }
};
class RegisterSpace{
    std::vector<RegisterRange> ranges;
    void _push_ranges(){}
    template<typename R,typename ...Rest>
    void _push_ranges(R&& r,Rest&& ...rest){
        ranges.emplace_back(std::forward<R>(r));
        _push_ranges(std::forward<Rest>(rest)...);
    }
    public:
        template<typename ...R>
        RegisterSpace(R&& ...r){
            _push_ranges(std::forward<R>(r)...);
        }
        const RegisterRange& operator[](std::uint32_t i) const{
            return ranges[i];
        }
        struct MatchResult{
            std::uint32_t index;
            reg offset;
            reg offset_to_shadow;
        };
        MatchResult test(reg r) const{
            [[assume(static_cast<std::uint32_t>(ranges.size())==ranges.size())]];
            RegisterRange::MatchResult result;
            for(std::uint32_t i=0;i<static_cast<std::uint32_t>(ranges.size());++i){
                result = ranges[i].test(r);
                switch(result.status){
                    case RegisterRange::INSIDE:
                        return {.index=i,.offset=result.offset,.offset_to_shadow=ranges[i].has_shadow()?ranges[i].size():static_cast<reg>(0)};
                    case RegisterRange::SHADOW:
                        return {.index=i,.offset=result.offset,.offset_to_shadow=0};
                    default:;
                }
            }
            std::unreachable();
        }
    };
constexpr static std::size_t DATA_INDEX = 0uz;
constexpr static std::size_t ACC_INDEX = 1uz;
constexpr static std::size_t BIT_INDEX = 2uz;
constexpr static std::size_t PTR_INDEX = 3uz;
constexpr static std::size_t MEM_INDEX = 4uz;
constexpr static std::size_t UTIL_INDEX = 5uz;
constexpr static std::size_t D15S_COUNTER_INDEX = 6uz;
constexpr static std::size_t PROGRAM_COUNTER_INDEX = 7uz;
constexpr static std::size_t WRITE_MASK_INDEX = 8uz;
constexpr static std::size_t LOOP_POINTER_INDEX = 9uz;
constexpr static std::size_t LOOP_CONTROL_INDEX = 10uz;
constexpr static std::size_t FUNCTION_CONTROL_INDEX = 11uz;
constexpr static std::uint64_t NMASK = ~static_cast<std::uint64_t>(0);
constexpr static std::size_t MEMSIZE = 1048576uz;
class ProgramState{
    RegisterSpace spc;
    std::array<std::byte,MEMSIZE> mem;
    reg_state regs;
    public:
        ProgramState(RegisterSpace s) : spc(std::move(s)), regs{0}{}
        template<typename I=std::uint64_t>
        I mem_read(std::uint64_t addr) const{
            I result;
            memcpy(&result,mem.data()+addr,sizeof(I));
            return result;
        }
        const RegisterRange& range(std::uint32_t index) const{
            return spc[index];
        }
        RegisterSpace::MatchResult range_of(reg r) const{
            return spc.test(r);
        }
        std::array<std::byte,MEMSIZE>& memory(){
            return mem;
        }
        const std::array<std::byte,MEMSIZE>& memory() const{
            return mem;
        }
        void mem_write(std::uint64_t value,std::uint64_t addr,std::uint64_t mask){
            std::uint64_t new_value{(mem_read(addr)&~mask) | (value&mask)};
            std::memcpy(mem.data()+addr,&new_value,sizeof(std::uint64_t));
        }
        std::uint64_t read(reg from) const{
            if(reg idx=from-spc[MEM_INDEX].begin();idx<spc[MEM_INDEX].size()){
                return mem_read(regs[spc[PTR_INDEX][from-spc[MEM_INDEX].begin()]]);
            }
            return regs[from];
        }
        std::uint64_t rreadbgn(std::uint32_t index) const{
            return read(range(index).begin());
        }
        void rsetbgn(std::uint64_t value,std::uint32_t index){
            set(value,range(index).begin());
        }
        void set(std::uint64_t value,reg to){
            regs[to] = value;
        }
        void write(std::uint64_t value,reg to,std::uint64_t mask){
            RegisterSpace::MatchResult rn{spc.test(to)};
            switch(rn.index){
                case MEM_INDEX:
                    mem_write(value,regs[spc[PTR_INDEX][rn.offset]],mask);
                    return;
                case DATA_INDEX:
                    if(rn.offset==0x0F){ // Write to d15/s
                        std::uint64_t v;
                        if(rn.offset_to_shadow==0){ // write is to shadow
                            v = rreadbgn(D15S_COUNTER_INDEX)+1;
                        }else{
                            v = 0;
                        }
                        rsetbgn(v,D15S_COUNTER_INDEX);
                    }
                    break;
                case WRITE_MASK_INDEX:
                    goto writer;
                case FUNCTION_CONTROL_INDEX:
                    rsetbgn(rreadbgn(PROGRAM_COUNTER_INDEX),FUNCTION_CONTROL_INDEX);
                    return write(value,range(PROGRAM_COUNTER_INDEX).begin(),mask);
                default:;
            }
            value = (regs[to]&~mask) | (value&mask);
            if(rn.index == LOOP_CONTROL_INDEX && value){
                rsetbgn(rreadbgn(LOOP_POINTER_INDEX),PROGRAM_COUNTER_INDEX);
            }
            set(rreadbgn(WRITE_MASK_INDEX),range(WRITE_MASK_INDEX).shadow(0));
            writer:
            set(value,to);
            if(rn.offset_to_shadow){
                set(value,to+rn.offset_to_shadow);
            }
        }
};
void opr(ProgramState& state,reg from,reg to,bool b0,bool b1){
    state.rsetbgn(state.rreadbgn(PROGRAM_COUNTER_INDEX)+2,PROGRAM_COUNTER_INDEX);
    std::uint64_t mask = state.read(state.range(WRITE_MASK_INDEX).shadow(0));
    if((b0 || b1) && from==to){
        if(b0){ // LDV
            std::int64_t immediate{state.mem_read<std::int32_t>(state.rreadbgn(PROGRAM_COUNTER_INDEX))};
            state.rsetbgn(state.rreadbgn(PROGRAM_COUNTER_INDEX)+4,PROGRAM_COUNTER_INDEX);
            if(b1){
                mask = NMASK;
            }
            state.write(std::uint64_t(immediate),to,mask);
        }else{ // OPR, zero register
            state.write(0,to,mask);
        }
    }else{
        RegisterSpace::MatchResult ran{state.range_of(to)};
        std::uint64_t value = state.read(from);
        if(b0){ // CAL
            switch(ran.index){
                case ACC_INDEX:{
                    std::uint64_t u0s = state.read(state.range(UTIL_INDEX).shadow(0));
                    std::uint64_t value2 = state.read(to);
                    switch(u0s&0b111){
                        case 0b000:
                            value2 += value;
                            break;
                        case 0b001:
                            value2 -= value;
                            break;
                        case 0b010:
                            value2 *= value;
                            break;
                        case 0b011:
                            std::tie(value2,value) = std::make_tuple(value/value2,value%value2);
                            break;
                        default: std::unreachable();
                    }
                    if(b1){
                        state.write((u0s&0b111)==0b011?value:value2,from,mask);
                    }
                    state.write(value2,to,mask);
                    break;
                }
                case BIT_INDEX:{
                    std::uint64_t u0s = state.read(state.range(UTIL_INDEX).shadow(0));
                    std::uint64_t value2 = state.read(to);
                    switch(u0s&0b111000){
                        case 0b000000:
                            value2 |= value;
                            break;
                        case 0b001000:
                            value2 &= value;
                            break;
                        case 0b010000:
                            value2 ^= value;
                            break;
                        case 0b011000:
                            value2 = ~value;
                            break;
                        case 0b100000:
                            value2 = value?NMASK:static_cast<std::uint64_t>(0);
                            break;
                        case 0b101000:
                            value2 = static_cast<std::uint64_t>(std::popcount(value));
                            break;
                        case 0b110000:
                            value2 = value2 << std::min(value,static_cast<std::uint64_t>(64));
                            break;
                        case 0b111000:
                            value2 = value2 >> std::min(value,static_cast<std::uint64_t>(64));
                            break;
                        default: std::unreachable();
                    }
                    if(b1){
                        state.write(value2,from,mask);
                    }
                    state.write(value2,to,mask);
                    break;
                }
                case UTIL_INDEX:
                    if(ran.offset) break;
                    if(b1){
                        from <<= 3;
                        mask = 0b111'000;
                    }else{
                        mask = 0b000'111;
                    }
                    state.write(from,to,mask);
                    break;
                case WRITE_MASK_INDEX:{
                    mask = (static_cast<std::uint64_t>(1) << (from&63)) - 1;
                    if(from&64){
                        state.write(~mask,to,NMASK);
                    }else{
                        state.write(mask,to,NMASK);
                    }
                    break;
                }
                case LOOP_CONTROL_INDEX:
                    if(b1){
                        value -= state.read(to);
                    }else{
                        value += state.read(to);
                    }
                    state.write(value,to,mask);
                    break;
                default:;
            }
        }else switch(ran.index){ // OPR
            case DATA_INDEX:
            case PTR_INDEX:
            case MEM_INDEX:
            case UTIL_INDEX:
            case D15S_COUNTER_INDEX:
            case PROGRAM_COUNTER_INDEX:
            case LOOP_POINTER_INDEX:
            case FUNCTION_CONTROL_INDEX:
                state.write(value,to,mask);
                break;
            case ACC_INDEX:
                if(b1){
                    state.write(value,to,mask);
                }else{
                    state.write(state.read(to)+value,to,mask);
                }
                break;
            case BIT_INDEX:
                if(b1){
                    state.write(value,to,mask);
                }else{
                    state.write(state.read(to)|value,to,mask);
                }
                break;
            case WRITE_MASK_INDEX:
                state.write(value,to,NMASK);
                break;
            case LOOP_CONTROL_INDEX:
                state.write(value,to,mask);
                break;
        }
    }
}
void step(ProgramState& state){
    std::uint64_t insaddr = state.rreadbgn(PROGRAM_COUNTER_INDEX);
    std::byte b0 = state.mem_read<std::byte>(insaddr);
    bool first{to_integer<bool>(b0&std::byte{0x80})}; // ADL
    reg sreg{to_integer<reg>(b0&std::byte{0x7F})};
    std::byte b1 = state.mem_read<std::byte>(insaddr+1);
    bool second{to_integer<bool>(b1&std::byte{0x80})};
    reg dreg{to_integer<reg>(b1&std::byte{0x7F})};
    opr(state,sreg,dreg,first,second);
}
#include<cppp/bfile.hpp>
#include<algorithm>
#include<cinttypes>
#include<cstdio>
#include<span>
using std::string_view_literals::operator ""sv;
void handle_syscall(ProgramState& state){
    std::uint64_t arg{state.read(state.range(UTIL_INDEX).shadow(3))};
    switch(state.read(state.range(UTIL_INDEX).shadow(2))){
        case 1:
            std::fputc(std::char_traits<char>::to_int_type(static_cast<char>(arg)),stdout);
            break;
        case 2:
            std::fflush(stdout);
            break;
        case 3:
            state.write(std::fgetc(stdin),state.range(UTIL_INDEX)[3],state.read(state.range(WRITE_MASK_INDEX).shadow(0)));
            break;
        case 4:
            std::exit(0);
        default: return;
    }
    state.write(0,state.range(UTIL_INDEX).shadow(2),NMASK);
}
void debug(const ProgramState& machine){
    std::cout << "PC = "sv << machine.rreadbgn(PROGRAM_COUNTER_INDEX) << std::endl;
    std::cout << "DC = "sv << machine.rreadbgn(D15S_COUNTER_INDEX) << std::endl;
}
int main(){
    ProgramState machine{{
        RegisterRange(0x00,0x10,true), // data d
        RegisterRange(0x20,0x08,true), // accumulator a
        RegisterRange(0x30,0x08,true), // bitfield b
        RegisterRange(0x40,0x10,false), // pointer p
        RegisterRange(0x50,0x10,false), // memory m
        RegisterRange(0x60,0x04,true), // utility u
        RegisterRange(0x68,0x01,false), // d23s counter dc
        RegisterRange(0x69,0x01,false), // program counter dc
        RegisterRange(0x6A,0x01,true), // write mask bm
        RegisterRange(0x6C,0x01,false), // loop pointer lp
        RegisterRange(0x6D,0x01,false), // loop control lc
        RegisterRange(0x6E,0x01,false), // function control fc
    }};
    {
        cppp::BinaryFile file{u8"prog.bin"sv,std::ios_base::in|std::ios_base::binary};
        file.read(machine.memory());
    }
    while(machine.read(machine.range(UTIL_INDEX).shadow(1))==0){
        // debug(machine);
        step(machine);
        handle_syscall(machine);
    }
    return 0;
}
