// Ruby module implementation: Ret::Afile::Win32::Fileinfo
// Author: Joel D.  Elkins <joel@elkins.com>
// Copyright (c) 2011 Joel D. Elkins.  All rights reserved.
//
// Part of the Ret package, a file browser for the Vim editor.

#if 1
#define _USE_NTDLL_
#endif

#include <ruby.h>
#include "fileinfo.h"

#include <stdio.h>
#include <windows.h>
#include <tchar.h>
#include "accctrl.h"
#include "aclapi.h"
#pragma comment(lib, "advapi32.lib")

#ifdef _USE_NTDLL_
#define DECL_IMPORT __declspec(dllimport)
#include "ddk/ntddk.h"
#include "security.h"
#endif

void Init_fileinfo()
{
	// modules
	VALUE mRet = rb_define_module("Ret");
	VALUE mRetAfile = rb_define_module_under(mRet, "Afile");
	VALUE mRetAfileWin32 = rb_define_module_under(mRetAfile, "Win32");
	VALUE mRetAfileWin32Fileinfo = rb_define_module_under(mRetAfileWin32, "Fileinfo");

	// module functions
	rb_define_module_function(mRetAfileWin32Fileinfo, "basic_test", mf_basic_test, 0);
	rb_define_module_function(mRetAfileWin32Fileinfo, "get_owner", mf_get_owner, 1);
}

VALUE mf_basic_test(VALUE self)
{
	const char *s = "hello world";
	return rb_str_new2(s);
}

// Reference: http://msdn.microsoft.com/en-us/library/aa446629(VS.85).aspx
VALUE mf_get_owner(VALUE self, VALUE file)
{
	DWORD dwRtnCode = 0;
	PSID pSidOwner = NULL;
	BOOL bRtnBool = TRUE;
	LPTSTR AcctName = NULL;
	LPTSTR DomainName = NULL;
	DWORD dwAcctName = 1, dwDomainName = 1;
	SID_NAME_USE eUse = SidTypeUnknown;
	HANDLE hFile = INVALID_HANDLE_VALUE;
	PSECURITY_DESCRIPTOR pSD = NULL;

	char *filename = StringValueCStr(file);
	char owner[128];
	char error[200];

#ifdef _USE_NTDLL_
	NTSTATUS status;
	OBJECT_ATTRIBUTES oa;
	IO_STATUS_BLOCK io;
	InitializeObjectAttributes(
			&oa,
			TEXT(filename),
			0,
			NULL,
			NULL);

	status = NtOpenfile(
			&hFile,
			READ_CONTROL,
			(POBJECT_ATTRIBUTES) &oa,
			(PIO_STATUS_BLOCK) &io,
			FILE_SHARE_VALID_FLAGS,
			FILE_OPEN_FOR_BACKUP_INTENT);

#else
	// Get the handle of the file object.
	hFile = CreateFile(
			TEXT(filename),
			//GENERIC_READ,
			READ_CONTROL,
			//FILE_SHARE_READ,
			FILE_SHARE_VALID_FLAGS,
			NULL,
			OPEN_EXISTING,
			FILE_ATTRIBUTE_NORMAL,
			NULL);
#endif

	// Check GetLastError for CreateFile error code.
	if (hFile == INVALID_HANDLE_VALUE) {
		DWORD dwErrorCode = 0;

		dwErrorCode = GetLastError();
		sprintf(error, "file %s: line %d: CreateFile() failed: %s: ", __FILE__, __LINE__, filename);
		FormatMessage(
				FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
				NULL,
				dwErrorCode,
				0,
				error + strlen(error),
				200,
				NULL);
		goto exception;
	}

	// Get the owner SID of the file.
	dwRtnCode = GetSecurityInfo(
			hFile,
			SE_FILE_OBJECT,
			OWNER_SECURITY_INFORMATION,
			&pSidOwner,
			NULL,
			NULL,
			NULL,
			&pSD);

	// Check GetLastError for GetSecurityInfo error condition.
	if (dwRtnCode != ERROR_SUCCESS) {
		DWORD dwErrorCode = 0;

		dwErrorCode = GetLastError();
		sprintf(error, "file %s: line %d: GetSecurityInfo() failed: %s: ", __FILE__, __LINE__, filename);
		FormatMessage(
				FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
				NULL,
				dwErrorCode,
				0,
				error + strlen(error),
				200,
				NULL);
		goto exception;
	}

	// First call to LookupAccountSid to get the buffer sizes.
	bRtnBool = LookupAccountSid(
			NULL,           // local computer
			pSidOwner,
			AcctName,
			(LPDWORD)&dwAcctName,
			DomainName,
			(LPDWORD)&dwDomainName,
			&eUse);

	// Reallocate memory for the buffers.
	AcctName = (LPTSTR)GlobalAlloc(
			GMEM_FIXED,
			dwAcctName);

	// Check GetLastError for GlobalAlloc error condition.
	if (AcctName == NULL) {
		DWORD dwErrorCode = 0;

		dwErrorCode = GetLastError();
		sprintf(error, "GlobalAlloc error = %d", dwErrorCode);
		goto exception;
	}

	DomainName = (LPTSTR)GlobalAlloc(
			GMEM_FIXED,
			dwDomainName);

	// Check GetLastError for GlobalAlloc error condition.
	if (DomainName == NULL) {
		DWORD dwErrorCode = 0;

		dwErrorCode = GetLastError();
		sprintf(error, "GlobalAlloc error = %d", dwErrorCode);
		goto exception;
	}

	// Second call to LookupAccountSid to get the account name.
	bRtnBool = LookupAccountSid(
			NULL,                   // name of local or remote computer
			pSidOwner,              // security identifier
			AcctName,               // account name buffer
			(LPDWORD)&dwAcctName,   // size of account name buffer 
			DomainName,             // domain name
			(LPDWORD)&dwDomainName, // size of domain name buffer
			&eUse);                 // SID type

	// Check GetLastError for LookupAccountSid error condition.
	if (bRtnBool == FALSE) {
		DWORD dwErrorCode = 0;

		dwErrorCode = GetLastError();
		if (dwErrorCode == ERROR_NONE_MAPPED)
			sprintf(error, "Account owner not found for specified SID.");
		else
			sprintf(error, "Error in LookupAccountSid.");
		goto exception;
	}

	// Return the account name.
	sprintf(owner, "%s\\%s", DomainName, AcctName);
	return rb_str_new2(owner);

exception:
	if (NULL != AcctName)              GlobalFree(AcctName);
	if (NULL != DomainName)            GlobalFree(DomainName);
	if (hFile != INVALID_HANDLE_VALUE) CloseHandle(hFile);
	rb_raise(rb_eRuntimeError, error);
	return Qnil;
}

