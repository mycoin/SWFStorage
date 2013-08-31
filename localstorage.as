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

/**
 * get the SharedObject's state
 *
 * @param {statusObject} the actionScript object instance
 * @return {Boolean} The new URL.
 */
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
/**
 * create localStorage space
 *
 * @param {String} the instance name
 * @return {Boolean} The state.
 */
function localStorage(appname:String = "cache"):Boolean{
    flso = SharedObject.getLocal(appname, '/');
    return getFlsoStatus( flso.flush(5000) ); // writes to file.
}
/**
 * the set method, as uesed in Javascript
 *
 * @param {String} key  key name
 * @param {String} the value, after function encodeURIComponent(string)
 * @return {Boolean} The state.
 */
function setItem(key:String = null, val:String=null):*{
    if( !flso ){
        localStorage(); //特殊情况
    } else {
        flso.data[key] = val;
        return getFlsoStatus(flso.flush());     
    }
}
/**
 * get method, as uesed in Javascript
 *
 * @param {String} key key name
 * @return {String} The value.
 */
function getItem(key:String = null):*{
    if(!flso){
        return null;
    } else {
        return flso.data[key];
    }
}
/**
 * set removeItem, as uesed in Javascript
 *
 * @param {String} key key name
 * @return {Boolean} The state.
 */
function removeItem(key:String = null):Boolean{
    flso.data[key] = null;
    delete flso.data[key];
    flso.flush();
    return getFlsoStatus(flso.flush(5000));
}
/**
 * notify errors call ExternalInterface.
 *
 * @param {string=} message error message  
 * @return {none}  
 */
function notifyErrors(message:String = null):void {
    ExternalInterface.call("function(){console && console.error('Error:Access forbidden on this domain.');}");
}
/**
 * notify ready
 */
function addCallbacks(): void {
	ExternalInterface.addCallback("localStorage",localStorage);
	ExternalInterface.addCallback("setItem",setItem);
	ExternalInterface.addCallback("getItem",getItem);
    ExternalInterface.addCallback("removeItem",removeItem);

	ExternalInterface.call(args["callback"] || "SWFLocalStorage"); // alert window that the Flash is ready.
}

//policy file url
policy = loaderInfo.url.substr(0, loaderInfo.url.lastIndexOf("/")) + "/storage-policy.xml";

loader.addEventListener(IOErrorEvent.IO_ERROR, notifyErrors);
loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, notifyErrors);
loader.addEventListener(Event.COMPLETE, function (event:Event):void {
	var contentXML:XML = new XML(event.target.data);

	var domain:String = ExternalInterface.call("function(){return '.' + location.hostname + '?' ;}");
    var locate:String = ExternalInterface.call("function(){return location.port;}");

	var list:XMLList = contentXML["allow-access-from"];
	for each(var item:XML in list) {
		var url:String = "." + item["@domain"] + "?"; //local, localhost.com not the same domain
        var port:String = item["@port"];

		if (domain.lastIndexOf(url) > -1 && domain.lastIndexOf(url) == (domain.length - url.length) || url == ".*?") { //endsWith
            if(port != "" && locate != port) {
                continue;
            }
			addCallbacks();
			return;
		}
	}
	notifyErrors();
});
loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(event:HTTPStatusEvent):void{
	if(event.status != 200) {
		ExternalInterface.call("function(){console && console.error('Error:Policy file not available.');}");
	}
});
loader.load(new URLRequest(policy));