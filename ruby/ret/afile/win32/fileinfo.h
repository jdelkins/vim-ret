// Ruby module: Ret::Afile::Win32::Fileinfo
// Author: Joel D. Elkins <joel@elkins.com>
// Copyright (c) 2011 Joel D. Elkins.  All rights reserved.
//
// Part of the Ret package, a file browser for the Vim editor. This module
// provides the Win32 api calls to get file metadata for dispaly to the user.
// In theory, Ruby libraries like win32-file should be able to produce this
// kind of thing similarly, but in my initial tests, that solution is too
// unstable, and also challenging to learn. C language examples for maneuvering
// the Win32 api are abundant, on the other hand, so I will at least start by
// using this external module.

// module initialization
void Init_mytest();

// module functions
VALUE mf_basic_test(VALUE self);
VALUE mf_get_owner(VALUE self, VALUE file);

