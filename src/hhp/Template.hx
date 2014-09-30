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


    /**
    * Render another template `fileOrClass` inside this one.
    *
    * If `fileOrClass` is a constant `String` it is treated as file path. Otherwise it's another template class.
    *
    * If you want to rendered template to extend custom class, provide a `baseClass` argument.
    *
    * This method is available only inside a template file of current template.
    */
    macro private function render (eThis:Expr, fileOrClass:Expr, parameters:Expr = null, baseClass:Expr = null) : Expr {
        var pos : Position = Context.currentPos();
        var className : String = null;

        var parent : String = switch (baseClass.expr) {
            case EConst(CIdent('null')) : 'hhp.Template';
            case _                      : ExprTools.toString(baseClass);
        }

        switch(fileOrClass.expr){
            //file name
            case EConst(CString(f)):
                className = hhp.TemplateBuilder.createClass(f, pos, parent);

            //classpath
            case _:
                className = ExprTools.toString(fileOrClass);
        }

        var block : Array<Expr> = [Context.parse('var hhp__render = new $className()', pos)];
        if( parameters != null ){
            switch(parameters.expr){
                case EObjectDecl(fields):
                    for(f in fields){
                        block.push( Context.parse('hhp__render.${f.field} = ' + ExprTools.toString(f.expr), pos) );
                    }
                case EConst(CIdent('null')):
                case _:
                    Context.error('"parameters" argument must be an EObjectDecl', pos);
            }
        }
        block.push( Context.parse('this._buffer += hhp__render.execute()', pos) );

        return {expr:EBlock(block), pos:pos};
    }//function render()


}//class Template