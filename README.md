HHP
===
HHP is a type-safe templating system for Haxe greatly inspired by PHP programming language templating possibilities.
HHP stands for `Haxe Hypertext Preprocessor`.

In PHP you can use plain PHP code inside of a template. This feature gives you unlimited control of template logic.
Thanks tou macros we can do the same thing with Haxe, but with additional error detection at compile time!

Features:
---------------
* Use any valid Haxe code inside templates.
* Compiler's code completion for variables used in template.
* Compile-time template parsing, which means you will get compiler notifications if:
    * If you try to pass to template a variable which is not used in template.
    * If you're passing a value of wrong type to a template variable.
* Include templates in templates.


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

```
var content : String = hhp.Hhp.render('templates/test.html', {
    title : 'Hello, HHP!',
    listSize : 2
});

trace(content);
```

*Advanced way*
```
//MyTemplate.hx
@:hhp('templates/test.html')
class MyTemplate extends hhp.Template {
    /**
    * Add template variable declaration if you want to constraint allowed type or set default value for this variable.
    * If variable used in template is not declared in a class, it will be Dynamic.
    */
    public var listSize : Int = 5;


    /**
    * You can also add any additional method and use them in a template.
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