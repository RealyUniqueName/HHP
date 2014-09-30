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
        tpl.total = 10;

        trace(tpl.execute());
    }//function main()


}//class Test