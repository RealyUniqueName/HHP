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
    }//function main()


}//class Test