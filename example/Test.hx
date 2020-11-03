package;


/**
* Description
*
*/
class Test {


    /**
    * Entry point
    *
    */
    static public function main () : Void {
        var tpl = new TestTemplate();
        tpl.title = 'Testing template';
        tpl.total = 12;

        trace(tpl.execute());

        var txt = hhp.Hhp.render('tpl/test1.html', {
            title : 'Testing template',
            total : 12
        });

        trace(txt);

        var tpl = hhp.Hhp.get('tpl/test1.html');
        tpl.title = 'Testing';
        tpl.total = 3;

        trace(tpl.execute());
    }//function main()


}//class Test