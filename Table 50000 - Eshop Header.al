// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

table 50000 "Eshop Header"
{
    Caption = 'E-shop Sales Header';
    fields
    {
        field(1;"Eshop No.";Code[20])
        {
        }
        field(2;"Sales Order No.";code[20])
        {
            //TableRelation = "Sales Header";
        }

    }

    keys
    {
        key(PK;"Eshop No.")
        {
            Clustered = true;
        }
    }
    
    var
        //myInt : Integer;

    trigger OnInsert();
    begin
    end;

    trigger OnModify();
    begin
    end;

    trigger OnDelete();
    begin
    end;

    trigger OnRename();
    begin
    end;

}