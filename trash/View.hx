package fst.view;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Position;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
#end


/**
* Base View class
*
*/
class View /* implements traits.IStatics */{

    /** content to output */
    private var _buffer : String = '';
    /** if user wants to ignore template file */
    private var _isLayoutDisabled : Bool = false;


    /**
    * Build view class (if not built yet) and create a new instance of it
    *
    */
    macro static public function instance (file:String, baseClass:Expr = null) : Expr {
        var expr : String = ExprTools.toString(baseClass);
        return fst.magic.ViewBuilder.instance(file, (expr == 'null' ? null : TypeTools.toString( Context.getType(expr) )) );
    }//function instance()


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
    public inline function echo (v:Dynamic) : Void {
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
    * Generate view content using template file (if any).
    * :WARNING:
    * This method will be overriden with macros
    *
    */
    public function getOutput () : String {
        return this._buffer;
    }//function getOutput()


    /**
    * Clear output buffer
    *
    */
    public inline function clearBuffer () : Void {
        this._buffer = '';
    }//function clearBuffer()


    /**
    * Do not use template file for output generation
    *
    */
    public function disableLayout () : Void {
        this._isLayoutDisabled = true;
    }//function disableLayout()


    /**
    * Render another template file inside this one
    *
    */
    macro private function render (eThis:Expr, fileOrClass:Expr, parameters:Expr = null) : Expr {
        var pos : Position = Context.currentPos();
        var className : String = null;

        switch(fileOrClass.expr){
            //file name
            case EConst(CString(f)):
                try{
                    className = fst.magic.ViewBuilder.createView(f, pos);
                }catch(e:fst.exception.Exception){
                    Context.error(e.message, pos);
                }
            //classpath
            case _:
                className = ExprTools.toString(fileOrClass);
        }

        var block : Array<Expr> = [Context.parse('var __renderView__ = new $className()', pos)];
        if( parameters != null ){
            switch(parameters.expr){
                case EObjectDecl(fields):
                    for(f in fields){
                        block.push( Context.parse('__renderView__.${f.field} = ' + ExprTools.toString(f.expr), pos) );
                    }
                case EConst(CIdent('null')):
                case _:
                    Context.error('"parameters" argument must be an EObjectDecl', pos);
            }
        }
        block.push( Context.parse('this._buffer += __renderView__.getOutput()', pos) );

        return {expr:EBlock(block), pos:pos};
    }//function render()


}//class View