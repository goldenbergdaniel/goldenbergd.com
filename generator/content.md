# Odin for C Programmers
### A primer on the Odin programming language for C veterans.
#### 2025.04.14

This post is meant to be a rundown of some of the part of Odin that might feel alien to a C developer. I will update this list periodically.

## Slices and Strings
A slice in Odin, denoted by `[]T`, is simply a struct containing a pointer and an `int` for length. Here's its layout in memory, taken directly from the Odin runtime.
```
Raw_Slice :: struct
{
	data: rawptr,
	len:  int,
}
```

And there you have it!
