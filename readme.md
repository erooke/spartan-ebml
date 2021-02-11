# Spartan EBML

A bare-bones EBML parsing library written in/for zig. 

## What?
For another project I needed to parse some information from a Matroska container. 
I wrote the dumbest thing that might work, and it did. So here it is.
Follows the [EBML spec](https://tools.ietf.org/html/rfc8794) sort of. 
Currently ignoring the header completely while parsing. 
This means we assume the default values for `EBMLMaxIDLength` (4) and `EBMLMaxSizeLength` (8). 
Which for parsing [mkv](https://www.matroska.org/technical/elements.html) files (the only thing I can actually confirms uses EBML) is correct.

## Usage
See the examples folders for examples on how to use the library. 
Documentation on each function can be found within the source.
Here's the synopsis:

The entire library revolves around the `Element` struct. 
This does nothing more than encode the location/id of an EBML element in a file.
  - `element = try Element.read(file: std.fs.File, offset: u64)` reads the element in `file` starting at `offset`.
  - `element.next(file: std.fs.File)`  gets the next element in the file (does not respect the tree structure)
  - `element.child(file: std.fs.File)` gets the first child element of a master element
  - `element.get(T: type, default: ?T, file: std.fs.File)` attempts to read the zig type `T` from the data of the element. 
  Only supports `int`'s (signed and unsigned) of up to 64 bits, `f32`, and `f64` for `T`. This is how you get:
    - Signed Integer Elements
    - Unsigned Integer Elements
    - Float Elements
    - Date Elements
  - `elements.get_slice(allocator: *std.mem.Allocator, file: std.fs.File)` gets the raw data of the element data.
  This is how one gets:
    - String Elements
    - UTF-8 Elements
    - Binary Elements

Part of the "Spartan" in "Spartan EBML" means you're on your own to parse/validate date elements, UTF-8 elements, and String elements. Sorry.
