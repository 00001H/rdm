COMPOPT := -std=c++26 -flto -fuse-linker-plugin -Wall -Wextra -Wpedantic -m64 -O0 $(cppinclude)
FINALOPT := $(COMPOPT) -s -static
main: main.cpp
	g++ $< -o $@ $(FINALOPT)
