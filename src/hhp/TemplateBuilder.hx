package hhp;

#if macro
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import sys.FileSystem;
import sys.io.File;
import haxe.macro.Type;

using StringTools;


/**
* Macros for building view classes
*
*/
class TemplateBuilder {
    /** HHP_META */
    static private inline var HHP_META = ':hhp';

    /** regexp to find fields for this view in template file */
    static private var _erThisField : EReg = ~/[^a-zA-Z0-9_]this\.([a-zA-Z0-9_]+)/;
    /** non alpha/numeric characters */
    static private var _erNonAlphaNum : EReg = ~/[^0-9a-zA-Z_]+/g;
    /** created classes */
    static private var _viewClasses : Map<String,TypeDefinition> = new Map();

    /** Cache for parsed templates */
    static private var _cache : Map<String,Array<Field>> = new Map();



    /**
    * Build template class
    *
    */
    macro static public function build () : Array<Field> {
        var cls : ClassType = Context.getLocalClass().get();

        var file : String = getTemplateFileFromMeta(cls.meta);
        //no template file
        if (file == null) {
            return null;
        }

        var cache : Array<Field> = TemplateBuilder._cache.get(file);
        if (cache != null) {
            return cache;
        }

        var tplFields : Array<Field> = parseTemplate(file);
        TemplateBuilder._cache.set(file, tplFields);

        var ownFields : Array<Field> = Context.getBuildFields();

        var found  : Bool = false;
        var fields : Array<Field> = [];
        for (field in tplFields) {
            found = false;

            for (i in 0...ownFields.length) {
                if (ownFields[i].name == field.name) {
                    found = true;

                    if (field.name == 'execute') {
                        fields.push( field );
                    } else {
                        fields.push( ownFields[i] );
                    }

                    break;
                }
            }

            if (!found) {
                fields.push(field);
            }
        }

        return fields;
    }//function build()


    /**
    * Extract template file path from `:hhp` meta of template class
    *
    */
    static private function getTemplateFileFromMeta (meta:MetaAccess) : String {
        if (meta.has(HHP_META)) {
            for (m in meta.get()) {
                if (m.name == HHP_META) {
                    if (m.params.length != 1) {
                        Context.error(HHP_META + ' accepts only one argument - path to template file', Context.currentPos());
                    }

                    switch (m.params[0].expr) {
                        case EConst(CString( file )) :
                            return file;

                        case _ :
                            Context.error(HHP_META + ' accepts only path to template file', Context.currentPos());
                    }
                }
            }
        }

        return null;
    }//function getTemplateFileFromMeta()


    /**
    * Generate fields for template class based on content of template `file`
    *
    */
    static private function parseTemplate (file:String) : Array<Field> {
        //file does not exist
        if (!FileSystem.exists(file)) {
            Context.error(HHP_META + ': unable to find ``$file``', Context.currentPos());
        }

        var content : String = File.getContent(file);

        var parentTypePath : TypePath = TemplateBuilder.str2TypePath('hhp.Template');
        var parent         : Type = Context.getType(parentTypePath.pack.join('.') + '.' + parentTypePath.name);

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
            if( block.fastCodeAt(0) == '='.code ){
                code += 'this._buffer += Std.string(' + block.substr(1) + ');';
            //code block
            }else if( block.substr(0, 3) == 'hhp' ){
                code += block.substr(3);
            }

            hxprev = hxpos + 2 + block.length + 2;

            //look for field names
            while( _erThisField.match(block) ){
                var name : String = _erThisField.matched(1);
                if( _erThisField.matchedRight().trim().fastCodeAt(0) != '('.code && !TemplateBuilder.hasField(parent, name) ){
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
        //extract function body and create execute() method
        switch( Context.parseInlineString(code, pos).expr ){
            case EFunction(_,{ret:_,params:_,expr:expr,args:_}):
                fields.push({
                    pos    : pos,
                    name   : 'execute',
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
    }//function parseTemplate()


    /**
    * Check if specified class or one of its parents has this field
    *
    */
    static public function hasField (cls:haxe.macro.Type, field:String) : Bool {
        switch(cls){
            case TInst(t,_):
                var type : ClassType = t.get();
                while( type != null ){
                    for(f in type.fields.get()){
                        if( f.name == field ) return true;
                    }

                    type = (type.superClass == null ? null : type.superClass.t.get());
                }
            case _:
                throw 'Only TInst is supported in TemplateBuilder.hasField()';
        }

        return false;
    }//function hasField()


    /**
    * Convert string represantation of classpath to TypePath structure
    *
    */
    static public function str2TypePath (className:String) : TypePath {
        var cls : Array<String> = className.split('.');
        return {
            name   : cls.pop(),
            pack   : cls,
            params : []
        };
    }//function str2TypePath()

}//class TemplateBuilder

#end