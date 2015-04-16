package hhp;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;


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



    /**
    * Render template.
    *
    * If you want rendered template to extend custom class, provide a `baseClass` argument.
    *
    * `parameters` should be anonymous object declaration.
    */
    macro static public function render (file:String, parameters:Expr = null, baseClass:Expr = null) : Expr {
        var pos : Position = Context.currentPos();
        var className : String = null;

        var parent : String = switch (baseClass.expr) {
            case EConst(CIdent('null')) : 'hhp.Template';
            case _                      : ExprTools.toString(baseClass);
        }

        className = hhp.TemplateBuilder.createClass(file, pos, parent);

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
        block.push( Context.parse('hhp__render.execute()', pos) );

        return {expr:EBlock(block), pos:pos};
    }//function render()


    /**
    * Get template instance which can be executed later.
    *
    * If you want rendered template to extend custom class, provide a `baseClass` argument.
    *
    * `parameters` should be anonymous object declaration.
    *
    * Returns an instance of `hhp.Template` class or instance of `baseClass`.
    * To generate content of that instance, use `.execute()` method.
    */
    macro static public function get (file:String, baseClass:Expr = null) : Expr {
        var pos : Position = Context.currentPos();
        var className : String = null;

        var parent : String = switch (baseClass.expr) {
            case EConst(CIdent('null')) : 'hhp.Template';
            case _                      : ExprTools.toString(baseClass);
        }

        className = hhp.TemplateBuilder.createClass(file, pos, parent);

        return Context.parse('new $className()', pos);
    }//function get()

}//class Hhp