// Ruby module implementation: Ret::Afile::Win32::Fileinfo
// Author: Joel D.  Elkins <joel@elkins.com>
// Copyright (c) 2011 Joel D. Elkins.  All rights reserved.
//
// Part of the Ret package, a file browser for the Vim editor.

// Includes

#include <ruby.h>
#include "fileinfo.h"

#include <stdio.h>
#include <windows.h>
#include <tchar.h>
#include "accctrl.h"
#include "aclapi.h"
#pragma comment(lib, "advapi32.lib")

// Static data related to file attributes

struct attribute {
	ID		symid;
	char		flag;
	unsigned long	mask;
	const char 	*name;
};
static struct attribute attr_table[] = {
	{0, 'd', FILE_ATTRIBUTE_DIRECTORY,           "FILE_ATTRIBUTE_DIRECTORY"},
	{0, 'l', FILE_ATTRIBUTE_REPARSE_POINT,       "FILE_ATTRIBUTE_REPARSE_POINT"},
	{0, 'r', FILE_ATTRIBUTE_READONLY,            "FILE_ATTRIBUTE_READONLY"},
	{0, 'h', FILE_ATTRIBUTE_HIDDEN,              "FILE_ATTRIBUTE_HIDDEN"},
	{0, 's', FILE_ATTRIBUTE_SYSTEM,              "FILE_ATTRIBUTE_SYSTEM"},
	{0, 'a', FILE_ATTRIBUTE_ARCHIVE,             "FILE_ATTRIBUTE_ARCHIVE"},
	{0, 'c', FILE_ATTRIBUTE_COMPRESSED,          "FILE_ATTRIBUTE_COMPRESSED"},
	{0, 'b', FILE_ATTRIBUTE_DEVICE,              "FILE_ATTRIBUTE_DEVICE"},
	{0, 'e', FILE_ATTRIBUTE_ENCRYPTED,           "FILE_ATTRIBUTE_ENCRYPTED"},
	{0, 'i', FILE_ATTRIBUTE_NOT_CONTENT_INDEXED, "FILE_ATTRIBUTE_NOT_CONTENT_INDEXED"},
	{0, 'o', FILE_ATTRIBUTE_OFFLINE,             "FILE_ATTRIBUTE_OFFLINE"},
	{0, 'z', FILE_ATTRIBUTE_SPARSE_FILE,         "FILE_ATTRIBUTE_SPARSE_FILE"},
	{0, 't', FILE_ATTRIBUTE_TEMPORARY,           "FILE_ATTRIBUTE_TEMPORARY"},
	{0, ' ', FILE_ATTRIBUTE_NORMAL,              "FILE_ATTRIBUTE_NORMAL"},
#if 0   // not implemented
	{0, FILE_ATTRIBUTE_VIRTUAL,             "FILE_ATTRIBUTE_VIRTUAL"}
#endif
};
#define attr_count 14

// Initialization

void Init_fileinfo()
{
	int i;

	// modules
	VALUE mRet = rb_define_module("Ret");
	VALUE mRetAfile = rb_define_module_under(mRet, "Afile");
	VALUE mRetAfileWin32 = rb_define_module_under(mRetAfile, "Win32");

	// classes
	VALUE cFileinfo = rb_define_class_under(mRetAfileWin32, "Fileinfo", rb_cObject);

	// methods
	rb_define_method(cFileinfo, "initialize", m_initialize, 1);

	// accessors
	rb_define_attr(cFileinfo, "filename", 1, 0);
	rb_define_attr(cFileinfo, "attributes", 1, 0);
	rb_define_attr(cFileinfo, "owner", 1, 0);

	// populate symbol table for file attributes
	for (i = 0; i < attr_count; i++) {
		struct attribute *a = &attr_table[i];
		a->symid = rb_intern(a->name);
	}
}

// Initialize class instance
VALUE m_initialize(VALUE self, VALUE file)
{
	rb_iv_set(self, "@filename", file);
	rb_iv_set(self, "@owner", get_owner(self, file));

	VALUE iv_attrs = get_attributes(self, file);
	rb_iv_set(self, "@attributes", iv_attrs);
	rb_define_singleton_method(iv_attrs, "to_s", singleton_attributes_to_s, 0);

	return self;
}

// Reference: http://msdn.microsoft.com/en-us/library/aa446629(VS.85).aspx
VALUE get_owner(VALUE self, VALUE file)
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

	// Get the handle of the file object.
	hFile = CreateFile(
			TEXT(filename),
			GENERIC_READ,
			FILE_SHARE_READ,
			NULL,
			OPEN_EXISTING,
			//FILE_ATTRIBUTE_NORMAL,
			FILE_FLAG_BACKUP_SEMANTICS,
			NULL);

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

	// Format the return value
	sprintf(owner, "%s\\%s", DomainName, AcctName);

	// Clean up
	GlobalFree(AcctName);
	GlobalFree(DomainName);
	CloseHandle(hFile);

	// Successful return
	return rb_str_new2(owner);

exception:
	if (NULL != AcctName)              GlobalFree(AcctName);
	if (NULL != DomainName)            GlobalFree(DomainName);
	if (hFile != INVALID_HANDLE_VALUE) CloseHandle(hFile);

	// the question: to raise or not ot raise?
	//rb_raise(rb_eRuntimeError, error);
	//return Qnil;
	
	return rb_str_new2("<unavailable>");
}

VALUE get_attributes(VALUE self, VALUE file)
{
	const char *filename = STR2CSTR(file);
	DWORD attr = GetFileAttributes(filename);
	VALUE ary = rb_ary_new();
	char error[300];
	int i;

	if (INVALID_FILE_ATTRIBUTES == attr) {
		sprintf(error, "file %s: line %d: GetFileAttributes() failed: %s: ", __FILE__, __LINE__, filename);
		goto exception;
	}

	for (i = 0; i < attr_count; i++) {
		struct attribute *a = &attr_table[i];
		if (attr & a->mask) {
			rb_ary_push(ary, ID2SYM(a->symid));
		}
	}

	return ary;

exception:
	rb_raise(rb_eRuntimeError, error);
	return Qnil;
}

VALUE singleton_attributes_to_s(VALUE self)
{
	int i;
	char output[16] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

	for (i = 0; i < attr_count; i++) {
		struct attribute *a = &attr_table[i];
		if (Qtrue == rb_ary_includes(self, ID2SYM(a->symid)))
			output[i] = a->flag;
		else
			output[i] = '-';
	}

	return rb_str_new2(output);
}

