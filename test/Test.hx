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

        // var txt = hhp.Hhp.render('test/tpl/test1.html', {
        //     title : 'Wtf!!!',
        //     total : 5
        // });


        // trace(txt);
    }//function main()


}//class Test