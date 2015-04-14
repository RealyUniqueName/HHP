HHP
===
HHP is a type-safe templating system for Haxe greatly inspired by PHP programming language templating possibilities.
HHP stands for `Haxe Hypertext Preprocessor`.

In PHP you can use plain PHP code inside of a template. This feature gives you unlimited control of template logic.
Thanks to macros we can do the same thing with Haxe, but with additional error detection at compile time!

Features:
---------------
* Use any valid Haxe code inside templates.
* Compiler's code completion for variables used in template.
* Compile-time template parsing, which means you will get compiler notifications if:
    * If you try to pass to template a variable which is not used in template.
    * If you're passing a value of wrong type to a template variable.
* Include templates in templates.

Rules:
---------------
1. In a template use tags `<?hhp ... ?>` to inline Haxe code. Use `this.echo(haxe_expression)` in inlined code to add `haxe_expression` value to output buffer.
1. Use `<?=haxe_expression?>` to add value of `haxe_expression` to output buffer.
1. Use `<?=this.render('another/template.html', ...)?>` to include another template (see [hhp.Template.render()](https://github.com/RealyUniqueName/HHP/blob/master/src/hhp/Template.hx#L82) method description)

Base templates path
---------------
If you have all your templates in for example `path/to/my/views/templates/` you can set this path
as base path for all templates using compiler flag:
```
--macro hhp.Hhp.basePath('path/to/my/views/templates/')
```
And omit this common path part in templates.

Examples:
---------------
Let's say we have template like this:
```html
<!-- templates/test.html -->
<html>
    <head>
        <title><?=this.title?></title>
    </head>
    <body>
        <ul>
            <?hhp
                for (i in 0...this.listSize) {
                    this.echo('<li>Item #${i + 1}</li>');
                }
            ?>
        </ul>
    </body>
</html>
```
Notice: inside of a template you must use `this` to access template variables and methods

*Simple way:*

```Haxe
var content : String = hhp.Hhp.render('templates/test.html', {
    title : 'Hello, HHP!',
    listSize : 2
});

trace(content);
```

*Advanced way*
```Haxe
//MyTemplate.hx
@:hhp('templates/test.html')
class MyTemplate extends hhp.Template {
    /**
    * Add template variable declaration if you want to constraint allowed type or
    *   set default value for this variable.
    * If variable used in template is not declared in a class, it will be Dynamic.
    */
    public var listSize : Int = 5;


    /**
    * You can also add any additional methods and use them in a template.
    */
}


//Main.hx
class Main {
    static public function main () {
        var tpl = new MyTemplate();
        tpl.listSize = 10; //integer variable
        tpl.| //get code completion with variables: title, listSize

        var content : String = tpl.execute();
        trace(content);
    }
}
```