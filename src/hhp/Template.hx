package hhp;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Position;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
#end


/**
* Base template class
*
*/
@:autoBuild(hhp.TemplateBuilder.build())
class Template {

    /** content to output */
    private var _buffer : String = '';
    /** if user wants to ignore template file */
    private var _isLayoutDisabled : Bool = false;


    /**
    * Constructor
    *
    */
    public function new () : Void {
        //code...
    }//function new()


    /**
    * Add value to output buffer.
    * It's an alias for Std.string() except NULL is converted to empty string
    *
    */
    public function echo (v:Dynamic) : Void {
        this._buffer += (v == null ? '' : Std.string(v));
    }//function echo()


    /**
    * Returns current buffer of view
    *
    */
    public inline function getBuffer () : String {
        return this._buffer;
    }//function getBuffer()


    /**
    * Generate content using template file (if any).
    * :WARNING:
    * This method will be overriden with macros
    *
    */
    public function execute () : String {
        return this._buffer;
    }//function execute()


    /**
    * Clear output buffer
    *
    */
    public function clearBuffer () : Void {
        this._buffer = '';
    }//function clearBuffer()


    /**
    * Do not use template file for output generation
    *
    */
    public function disableLayout () : Void {
        this._isLayoutDisabled = true;
    }//function disableLayout()

}//class Template