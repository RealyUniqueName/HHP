package fst.magic;

#if macro

import fst.exception.Exception;
import fst.tools.AAccess;
import fst.tools.FSTools;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import sys.io.File;

using StringTools;

/**
* Macros for building view classes
*
*/
class ViewBuilder {

    /** regexp to find fields for this view in template file */
    static private var _erThisField : EReg = ~/[^a-zA-Z0-9_]this\.([a-zA-Z0-9_]+)/;
    /** non alpha/numeric characters */
    static private var _erNonAlphaNum : EReg = ~/[^0-9a-zA-Z_]+/g;
    /** created classes */
    static private var _viewClasses : Map<String,TypeDefinition> = new Map();


    /**
    * Build view class based on template file and create an instance of it
    *
    */
    static public function instance (file:String, baseClass:String = null) : Expr {
        var pos : Position = Context.currentPos();
        var className : String = fst.magic.ViewBuilder.createView(file, pos, baseClass);

        return Context.parse('new $className()', pos);
    }//function instance()


    /**
    * Build classes for views
    *
    */
    static public function buildViews () : Void {
        var pos       : Position = Context.currentPos();
        var routes    : AAccess = Magic.config.config.routes;

        for(name in routes.fields()){
            ViewBuilder.createView(routes[name].view, pos);
        }
    }//function buildViews()


    /**
    * Create view class based on template file
    *
    */
    static public function createView (file:String, pos:Position = null, baseClass:String = null) : String {
        var key : String = (baseClass == null ? file : file + baseClass);
        var className : String = ViewBuilder.file2Class(file);
        if( className == null ) return baseClassName();
        if( baseClass != null ) className += '_' + baseClass.replace('.', '_');

        if( pos == null ) pos = Context.currentPos();
        var type : TypeDefinition = ViewBuilder._viewClasses.get(key);

        if( type == null ){
            var fields : Array<Field> = [];

            if( file != null ){
                fields = fields.concat( ViewBuilder._genFields(
                    ViewBuilder.basePath() + file,
                    baseClass == null ? null : Context.getType(baseClass)
                ) );
            }

            type = {
                pos      : pos,
                params   : [],
                pack     : ['fst', 'view'],
                name     : className,
                meta     : [],
                kind     : TDClass(
                    (baseClass == null ? ViewBuilder.baseTypePath() : Magic.str2TypePath(baseClass)),
                    [],
                    false
                ),
                isExtern : false,
                fields   : fields
            };

            ViewBuilder._viewClasses.set(key, type);

            Context.defineType(type);
        }

        return 'fst.view.' + className;
    }//function createView()


    /**
    * Generate getOutput() and fields for view class
    *
    */
    static private function _genFields (file:String, parent:haxe.macro.Type = null) : Array<Field> {
        var content : String = null;
        try{
            content = File.getContent(file);
        }catch(e:Dynamic){
            throw new Exception('Unable to read file: ' + file);
        }

        if( parent == null ){
            var tpath  : TypePath = ViewBuilder.baseTypePath();
            parent = Context.getType(tpath.pack.join('.') + '.' + tpath.name);
        }
        var fields : Array<Field> = [];
        var pos    : Position = Context.makePosition({min:0, max:0, file:file});

        var code   : String = 'if( this._isLayoutDisabled ) return this._buffer;';
        var block  : String = '';
        var hxprev : Int = 0;
        var hxpos  : Int = -1;
        while( (hxpos = content.indexOf('<?', hxprev)) != -1 ){
            if( hxpos > 0 ){
                code += 'this._buffer += "' + content.substring(hxprev, hxpos).replace('\\', '\\\\').replace('"', '\\"') + '";';
            }

            block = content.substring(hxpos + 2, content.indexOf('?>', hxpos));
            //short echo
            if( block.charAt(0) == '=' ){
                code += 'this._buffer += Std.string(' + block.substr(1) + ');';
            //code block
            }else if( block.substr(0, 4) == 'haxe' ){
                code += block.substr(4);
            }

            hxprev = hxpos + 2 + block.length + 2;

            //look for field names
            while( _erThisField.match(block) ){
                var name : String = _erThisField.matched(1);
                if( _erThisField.matchedRight().trim().charAt(0) != '(' && !Magic.hasField(parent, name) ){
                    fields.push({
                        pos    : pos,
                        name   : name,
                        meta   : [],
                        kind   : FVar(TPath({name : 'Dynamic', pack : [], params : [] }), null),
                        doc    : '',
                        access : [APublic]
                    });
                };
                block = block.replace(name, ' ');
            }
        }
        code += 'this._buffer += "' + content.substring(hxprev).replace('\\', '\\\\').replace('"', '\\"') + '";';

        code = 'function(){' + code + 'return this._buffer;}';
        //extract function body and create getOutput() method
        switch( Context.parseInlineString(code, pos).expr ){
            case EFunction(_,{ret:_,params:_,expr:expr,args:_}):
                fields.push({
                    pos    : pos,
                    name   : 'getOutput',
                    meta   : [],
                    kind   : FFun({
                        ret    : TPath({name : 'String', pack : [], params : [] }),
                        params : [],
                        args   : [],
                        expr   : expr
                    }),
                    doc    : 'Get generated content',
                    access : [AOverride, APublic]
                });
            case _:
        }

        return fields;
    }//function _genFields()


    /**
    * Manually build view class
    *
    */
    static public function build (file:String) : Array<Field> {
        var fields : Array<Field> = Context.getBuildFields();
        var pos    : Position = Context.currentPos();
        var cls    = Context.getLocalClass().get();
        var parent : haxe.macro.Type = (
            cls.superClass != null
                ? Context.getType(cls.superClass.t.toString())
                : null
        );

        try{
            fields = fields.concat( ViewBuilder._genFields(ViewBuilder.basePath() + file, parent) );
        }catch(e:Exception){
            Sys.println(e.message);
            haxe.macro.Context.error('Build failed', pos);
        }

        return fields;
    }//function build()


    /**
    * Base class for generated view classes
    *
    */
    static public inline function baseTypePath () : TypePath {
        var cls : String = Magic.getDeep(Magic.config.config, 'app.classes.view');
        return Magic.str2TypePath(cls == null ? 'fst.view.View' : cls);
    }//function baseTypePath()


    /**
    * Base class for view classes
    *
    */
    static public function baseType () : haxe.macro.Type {
        if( Magic.config.config.app != null && Magic.config.config.app.classes != null && Magic.config.config.app.classes.view != null ){
            return Context.getType(Magic.config.config.app.classes.view);
        }else{
            return Context.getType('fst.view.View');
        }
    }//function baseType()


    /**
    * Base classname as string
    *
    */
    static public inline function baseClassName () : String {
        if( Magic.config.config.app != null && Magic.config.config.app.classes != null && Magic.config.config.app.classes.view != null ){
            return Magic.config.config.app.classes.view;
        }else{
            return 'fst.view.View';
        }
    }//function baseClassName()


    /**
    * Basepath for template files for views
    *
    */
    static public inline function basePath () : String {
        if( Magic.config.config.app != null && Magic.config.config.app.path != null && Magic.config.config.app.path.view != null ){
            return FSTools.ensureSlash(Magic.config.config.app.path.view);
        }else{
            return './';
        }
    }//function basePath()


    /**
    * Convert filename to classname
    *
    */
    static public inline function file2Class (file:String) : String {
        return (file == null ? null : 'View_' + _erNonAlphaNum.replace(file, '_'));
    }//function file2ClassName()

}//class ViewBuilder

#end