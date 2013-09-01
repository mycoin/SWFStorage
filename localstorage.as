/**
 * SWFLocalStorage - a JavaScript library for cross-domain flash LocalStorage
 *
 * https://github.com/mycoin/localstorage
 *
 * Copyright 2012 Baidu Inc. All rights reserved.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * date:    2013/08/28
 */
import flash.display.Sprite;
import flash.net.SharedObject;
import flash.net.SharedObjectFlushStatus;
import flash.external.ExternalInterface;
import flash.system.Security;

ExternalInterface.marshallExceptions = true;
/**
 * Our Local Shared Object (LSO) - this is where all the magic happens!
 */
var flsso: SharedObject = null;

/**
 * create localStorage space
 *
 * @param {String} the instance name
 * @return {Boolean} The state.
 */
/**
 * start, sets up everything and exports all config.
 * Call this automatically by setting Publish > Class tp "Storage" in your .fla properties.
 *
 * If javascript is unable to access this object and not recieving any log messages (at wh
 */

function start(): Boolean {
    //The name of LSO
    var name: String = "baidu";

    if (flsso != null) {
        Log("The sharedObject has already created .", 'warn');
        return false;
    }
    // grab the namespace if supplied
    if (this.loaderInfo.parameters["name"]) {
        name = this.loaderInfo.parameters["name"];
    }
    /**
     * The path of LSO
     * This defaults to "/path/to/localStorage.swf" which prevents any other .swf from reading it's values.
     * Similar to cookies, set it to "/" to allow any other .swf on the domain to read from this LSO.
     */
    var localPath: String = "/";

    // grab the path if supplied
    if (this.loaderInfo.parameters["path"]) {
        localPath = this.loaderInfo.parameters["path"];
    }

    var secure: Boolean = false;
    // grab the secure config if supplied
    //see: http://livedocs.adobe.com/flash/9.0_cn/main/wwhelp/wwhimpl/common/html/wwhelp.htm?context=LiveDocs_Parts&file=00002122.html
    if (this.loaderInfo.parameters["secure"]) {
        secure = ("true" == this.loaderInfo.parameters["secure"]);
    }

    //By default, an application can create shared objects of up 100 KB of data per domain. 
    try {
        Log("LocalStorage, name: " + name + ", localPath: " + localPath + ", secure: " + secure);
        flsso = SharedObject.getLocal(name, localPath, secure);
    } catch (e: Error) {
        // user probably unchecked their "allow third party data" in their global flash settings
        Log('Unable to create a local sharedObject. -' + e.message, 'warn');
        return false;
    }
    return flush();
}

/**
 * Flushes changes to the SharedObject instance
 */

function flush(): Boolean {
    var result: Boolean = false;
    var status: String = null;
    try {
        status = flsso.flush(10000);
    } catch (e: Error) {
        Log("Error: Could not write SharedObject to disk - " + e.message);
    }
    if (status != null) {
        switch (status) {
            case SharedObjectFlushStatus.PENDING:
                Log("Requesting permission to save SharedObject...");
                flsso.addEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
                break;
            case SharedObjectFlushStatus.FLUSHED:
                // don't really need another message when everything works right but exports it.
                result = true;
                break;
        }
    }
    return result;
}
/**
 * This happens if the user is prompted about saving locally
 */

function onFlushStatus(event: NetStatusEvent): void {
    Log("User closed permission dialog...");
    switch (event.info.code) {
        case "SharedObject.Flush.Success":
            Log("User granted permission -- value saved.");
            break;
        case "SharedObject.Flush.Failed":
            Log("User denied permission -- value not saved.");
            break;
    }
    flsso.removeEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
}
/**
 * Saves the data to the LSO, and then flushes it to the disk
 *
 * @param {string} key
 * @param {string} value - Expects a string. Objects will be converted to strings, functions tend to cause problems.
 */

function setItem(key: String = null, value: *= null): * {
    if (typeof value != "string") {
        value = value.toString();
    }
    flsso.data[key] = value;
    return flush();
}
/**
 * get method, as uesed in Javascript
 *
 * @param {String} key key name
 * @return {String} The value.
 */

function getItem(key: String): * {
    try {
        return flsso.data[key];
    } catch (e: Error) {
        Log('Unable to read data - ' + e.message);
    }
}
/**
 * get all method, as uesed in Javascript
 *
 * @param {String} key key name
 * @return {String} The value.
 */

function getAllItem(): * {
    if (!flsso) {
        return null;
    } else {
        return flsso.data;
    }
}
/**
 * set removeItem, as uesed in Javascript
 *
 * @param {String} key key name
 * @return {Boolean} The state.
 */

function removeItem(key: String = null): Boolean {
    try {
        flsso.data[key] = null;
        delete flsso.data[key];
        return flush();
    } catch (e: Error) {
        Log("Error deleting key - " + e.message);
    }
    return false;
}

/**
 * notify ready
 */
function addInterface(): void {
    try {
        // expose our external interface
        ExternalInterface.addCallback("setItem", setItem);
        ExternalInterface.addCallback("getAllItem", getAllItem);
        ExternalInterface.addCallback("getItem", getItem);
        ExternalInterface.addCallback("removeItem", removeItem);
        Log('ready!');

        start();
        // if onload was set in the flashvars, assume it's a string function name and call it after started.
        // (This means that the function must be in the global scope. I'm not sure how to call a scoped function.)
        var callback = this.loaderInfo.parameters["onload"];
        if (callback) {
            // and we're done!
            try {
                ExternalInterface.call(callback);
            } catch (e: Error) {
                Log("An Error occurred in method " + callback + " that provided.", "warn");
            }
        }
    } catch (e: SecurityError) {
        Log("A SecurityError occurred: " + e.message, "warn");
    } catch (e: Error) {
        Log("An Error occurred: " + e.message, "warn");
    }
}

/**
 * main entry, sets up everything and logs any errors.
 * Call this automatically by setting Publish > Class tp "Storage" in your .fla properties.
 *
 * If javascript is unable to access this object and not recieving any log messages (at wh
 */
function entry(): * {
    // Make sure we can talk to javascript at all
    if (!ExternalInterface.available) {
        localLog("External Interface is not avaliable.");
        return false;
    }
    Log('Initializing...');
    var allow = this.loaderInfo.parameters["token"] == "false";
    if (allow) {
        // This is necessary to work cross-domain
        // Ideally you should add only the domains that you need.
        // More information: http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/system/Security.html#allowDomain%28%29
        Security.allowDomain("*");
        Security.allowInsecureDomain("*");

        Log('Access allowed from all domains. ');
        addInterface();
        return null;
    }
    var domain: String = ExternalInterface.call("function(){return '.' + location.hostname + '?' ;}");
    var locate: String = ExternalInterface.call("function(){return location.port;}");

    var net: URLLoader = new URLLoader();
    net.addEventListener(Event.COMPLETE, function(event: Event): void {
        var contentXML: XML = new XML(event.target.data);
        var list: XMLList = contentXML["allow-access-from"];
        for each(var item: XML in list) {
            var url: String = "." + item["@domain"] + "?"; //local, localhost.com not the same domain
            var port: String = item["@port"];

            if (domain.lastIndexOf(url) > -1 && domain.lastIndexOf(url) == (domain.length - url.length) || url == ".*?") { //endsWith
                if (port != "" && locate != port) {
                    continue;
                }
                addInterface();
                return;
            }
        }
        Log('Access forbidden for this domain..', 'error');
    });
    net.addEventListener(IOErrorEvent.IO_ERROR, onError);
    net.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    net.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(event: HTTPStatusEvent): void {
        if (event.status != 200) {
            onError("Policy file not available.");
        }
    });
    net.load(new URLRequest(loaderInfo.url.substr(0, loaderInfo.url.lastIndexOf("/")) + "/storage-policy.xml"));
}

/**
 * Last-resort logging used when communication with javascript fails or isn't avaliable.
 * The messages should appear in the flash object, but they might not be pretty.
 */

function localLog(str: String): void {
    // We can't talk to javascript for some reason.
    // Attempt to show this to the user (normally this swf is hidden off screen, so regular users shouldn't see it)
    var textArea: TextField;
    if (!textArea) {
        // create the text field if it doesn't exist yet
        textArea = new TextField();
        textArea.width = 450; // I suspect there's a way to do "100%"...
        addChild(textArea);
    }
    textArea.appendText(str + "\n");
}

/**
 * Attempts to log messages to the supplied javascript logFn,
 * if that fails it passes them to localLog()
 */

function Log(str: * , type: String = "debug"): void {
    var logFunc: String = null;

    // since even logging involves communicating with javascript,
    // the next thing to do is find the external log function
    if (this.loaderInfo.parameters["log"]) {
        logFunc = this.loaderInfo.parameters["log"];
    }
    if (logFunc) {
        try {
            ExternalInterface.call(logFunc, str, type);
        } catch (error: Error) {}
    } else {
        localLog(str);
    }
}
/**
 * Attempts to notify JS when there was an error during initialization
 *
 * @param {string=} message error message
 * @exception attempting callback error.
 */

function onError(message: String=null): void {
    try {
        if (ExternalInterface.available && this.loaderInfo.parameters["onerror"]) {
            ExternalInterface.call(this.loaderInfo.parameters["onerror"], message);
        } else {
            Log(message, "error");
        }
    } catch (error: Error) {
        Log('Error attempting with onerror callback.', "error");   
    }
}

entry();