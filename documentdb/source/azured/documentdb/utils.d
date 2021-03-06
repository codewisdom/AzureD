﻿module azured.documentdb.utils;

import azured.documentdb.connection;
import std.datetime;
import std.base64;
import std.format;
import std.uni;
import deimos.openssl.hmac;
import vibe.inet.message;
import vibe.textfilter.urlencode;
import vibe.http.client;

private string getAuthorizationToken(AzureDocumentDBConnection conn, string verb, string resourceType, string resourceId, SysTime time)
{
	string key = conn.MasterKey == null ? conn.ResourceKey : conn.MasterKey;
	ubyte[] mkey = Base64.decode(key);
	string sigstr = format("%s\n%s\n%s\n%s\n", verb.toLower(), resourceType.toLower(), resourceId.toLower(), toRFC822DateTimeString(time));
	ubyte[] temp = cast(ubyte[])sigstr;
	ubyte* digestptr = HMAC(EVP_sha256(), mkey.ptr, cast(int)mkey.length, temp.ptr, cast(int)temp.length, null, null);
	ubyte[32] digest;
	for(int i=0;i<32;i++)
		digest[i] = digestptr[i];
	return urlEncode(format("type=master&ver=1.0&sig=%s", Base64.encode(digest)));
}

public void writeRequiredHeaders(HTTPClientRequest req, AzureDocumentDBConnection conn, string verb, string resourceType, string resourceId)
{
	//Write required headers
	SysTime reqTime = Clock.currTime().toUTC();
	req.headers.addField("Authorization", getAuthorizationToken(conn, verb, resourceType, resourceId, reqTime));
	req.headers.addField("x-ms-date", toRFC822DateTimeString(reqTime));
}