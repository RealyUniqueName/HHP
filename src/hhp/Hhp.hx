package hhp;


using StringTools;



/**
* HHP - Haxe Hypertext Preprocessor
*
*/
class Hhp {
    /** base path for template files */
    static public var path (default,null) : String = './';


    /**
    * Use this method with `--macro` compiler flag to set base path for all template files.
    * E.g.: --macro hhp.Hhp.basePath('data/templates/')
    *
    */
    macro static public function basePath (path:String) : Void {
        path = path.trim();
        var lastChar = path.charAt(path.length - 1);
        if (lastChar != '/' && lastChar != '\\') {
            path += '/';
        }

        Hhp.path = path;
    }//function basePath()





}//class Hhp