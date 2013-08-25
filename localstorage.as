/*!
 * SWFLocalStorage actionscript.
 * Copyright 2012 Baidu Inc. All rights reserved.
 *
 * file:    localstorage.as
 * author:  nqliujiangtao@gmail.com
 * github:  https://github.com/mycoin/localstorage
 * date:    2013/08/28
 */
import flash.display.Sprite;
import flash.net.SharedObject;
import flash.net.SharedObjectFlushStatus;
import flash.external.ExternalInterface;
import flash.system.Security;

ExternalInterface.marshallExceptions = true;

var flso:SharedObject;
var state:Boolean;
var args:Object = root.loaderInfo.parameters; //get FlashVars list.
var loader:URLLoader = new URLLoader();
var policy:String;

function getFlsoStatus(statusObject):Boolean{
    switch( statusObject ){
        case SharedObjectFlushStatus.FLUSHED:
            state  = true;
            break;
        case SharedObjectFlushStatus.PENDING:
            state = false;
            break;
    }
    return state;
}

function localStorage(appname:String = "cache"):Boolean{
    flso = SharedObject.getLocal(appname, '/');
    return getFlsoStatus( flso.flush(5000) ); // writes to file.
}

function setItem(key:String = null, val:String=null):*{
    if( !flso ){
        localStorage(); //特殊情况
    } else {
        flso.data[key] = val;
        return getFlsoStatus(flso.flush());     
    }
}

function getItem(key = null):*{
    if(!flso){
        return;
    } else {
        return flso.data[key];
    }
}

function removeItem(key = null):Boolean{
    flso.data[key] = null;
    delete flso.data[key];
    flso.flush();
    return getFlsoStatus(flso.flush(5000));
}

function showErrors():void {
    ExternalInterface.call("function(){console && console.error('Error:this site domain is not in the whitelist.');}");
}

function addCallbacks(): void {
	ExternalInterface.addCallback("localStorage",localStorage);
	ExternalInterface.addCallback("setItem",setItem);
	ExternalInterface.addCallback("getItem",getItem);
	ExternalInterface.addCallback("removeItem",removeItem);

	ExternalInterface.call(args["callback"] || "SWFLocalStorage"); // alert window that the Flash is ready.
}

//policy file url
policy = loaderInfo.url.substr(0, loaderInfo.url.lastIndexOf("/")) + "/storage-policy.xml";

loader.addEventListener(IOErrorEvent.IO_ERROR, showErrors);
loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, showErrors);
loader.addEventListener(Event.COMPLETE, function (event:Event):void {
	var contentXML:XML = new XML(event.target.data);
	var domain:String = ExternalInterface.call("function(){return '.' + location.hostname + '$' ;}");
	var list:XMLList = contentXML["allow-access-from"];
	var item:XML;
	for each(item in list) {
		var url:String = "." + item.@url + "$"; //local, localhost.com not the same domain
		if (domain.lastIndexOf(url) > -1 && domain.lastIndexOf(url) == (domain.length - url.length) || url == "*") { //endsWith
			addCallbacks();
			return;
		}
	}
	showErrors();
});
loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(event:HTTPStatusEvent):void{
	if(event.status == 404) {
		ExternalInterface.call("function(){console && console.error('Error:policy file (storage-policy.xml) not found.');}");
	}
});
loader.load(new URLRequest(policy));