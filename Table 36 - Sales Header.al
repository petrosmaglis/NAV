table 36 "Sales Header"
{
    // version NAVW111.00

    Caption = 'Sales Header';
    DataCaptionFields = "No.","Sell-to Customer Name";
    LookupPageID = 45;

    fields
    {
        field(1;"Document Type";Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2;"Sell-to Customer No.";Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate();
            begin
                CheckCreditLimitIfLineNotInsertedYet;
                IF "No." = '' THEN
                  InitRecord;
                TESTFIELD(Status,Status::Open);
                IF ("Sell-to Customer No." <> xRec."Sell-to Customer No.") AND
                   (xRec."Sell-to Customer No." <> '')
                THEN BEGIN
                  IF ("Opportunity No." <> '') AND ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) THEN
                    ERROR(
                      Text062,
                      FIELDCAPTION("Sell-to Customer No."),
                      FIELDCAPTION("Opportunity No."),
                      "Opportunity No.",
                      "Document Type");
                  IF GetHideValidationDialog OR NOT GUIALLOWED THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(ConfirmChangeQst,FALSE,SellToCustomerTxt);
                  IF Confirmed THEN BEGIN
                    SalesLine.SETRANGE("Document Type","Document Type");
                    SalesLine.SETRANGE("Document No.","No.");
                    IF "Sell-to Customer No." = '' THEN BEGIN
                      IF SalesLine.FINDFIRST THEN
                        ERROR(
                          Text005,
                          FIELDCAPTION("Sell-to Customer No."));
                      INIT;
                      SalesSetup.GET;
                      "No. Series" := xRec."No. Series";
                      InitRecord;
                      InitNoSeries;
                      EXIT;
                    END;

                    CheckShipmentInfo(SalesLine,FALSE);
                    CheckPrepmtInfo(SalesLine);
                    CheckReturnInfo(SalesLine,FALSE);

                    SalesLine.RESET;
                  END ELSE BEGIN
                    Rec := xRec;
                    EXIT;
                  END;
                END;

                IF ("Document Type" = "Document Type"::Order) AND
                   (xRec."Sell-to Customer No." <> "Sell-to Customer No.")
                THEN BEGIN
                  SalesLine.SETRANGE("Document Type",SalesLine."Document Type"::Order);
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Purch. Order Line No.",'<>0');
                  IF NOT SalesLine.ISEMPTY THEN
                    ERROR(
                      Text006,
                      FIELDCAPTION("Sell-to Customer No."));
                  SalesLine.RESET;
                END;

                GetCust("Sell-to Customer No.");

                Cust.CheckBlockedCustOnDocs(Cust,"Document Type",FALSE,FALSE);
                Cust.TESTFIELD("Gen. Bus. Posting Group");
                "Sell-to Customer Template Code" := '';
                "Sell-to Customer Name" := Cust.Name;
                "Sell-to Customer Name 2" := Cust."Name 2";
                CopySellToCustomerAddressFieldsFromCustomer(Cust);
                IF NOT SkipSellToContact THEN
                  "Sell-to Contact" := Cust.Contact;
                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
                "VAT Registration No." := Cust."VAT Registration No.";
                "VAT Country/Region Code" := Cust."Country/Region Code";
                "Shipping Advice" := Cust."Shipping Advice";
                "Responsibility Center" := UserSetupMgt.GetRespCenter(0,Cust."Responsibility Center");
                VALIDATE("Location Code",UserSetupMgt.GetLocation(0,Cust."Location Code","Responsibility Center"));

                IF "Sell-to Customer No." = xRec."Sell-to Customer No." THEN
                  IF ShippedSalesLinesExist OR ReturnReceiptExist THEN BEGIN
                    TESTFIELD("VAT Bus. Posting Group",xRec."VAT Bus. Posting Group");
                    TESTFIELD("Gen. Bus. Posting Group",xRec."Gen. Bus. Posting Group");
                  END;

                "Sell-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Sell-to IC Partner Code" <> '') AND ("IC Direction" = "IC Direction"::Outgoing);

                IF Cust."Bill-to Customer No." <> '' THEN
                  VALIDATE("Bill-to Customer No.",Cust."Bill-to Customer No.")
                ELSE BEGIN
                  IF "Bill-to Customer No." = "Sell-to Customer No." THEN
                    SkipBillToContact := TRUE;
                  VALIDATE("Bill-to Customer No.","Sell-to Customer No.");
                  SkipBillToContact := FALSE;
                END;
                VALIDATE("Ship-to Code",'');

                GetShippingTime(FIELDNO("Sell-to Customer No."));

                IF (xRec."Sell-to Customer No." <> "Sell-to Customer No.") OR
                   (xRec."Currency Code" <> "Currency Code") OR
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") OR
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                THEN
                  RecreateSalesLines(SellToCustomerTxt);

                IF NOT SkipSellToContact THEN
                  UpdateSellToCont("Sell-to Customer No.");

                IF (xRec."Sell-to Customer No." <> '') AND (xRec."Sell-to Customer No." <> "Sell-to Customer No.") THEN
                  RecallModifyAddressNotification(GetModifyCustomerAddressNotificationId);
            end;
        }
        field(3;"No.";Code[20])
        {
            Caption = 'No.';

            trigger OnValidate();
            begin
                IF "No." <> xRec."No." THEN BEGIN
                  SalesSetup.GET;
                  NoSeriesMgt.TestManual(GetNoSeriesCode);
                  "No. Series" := '';
                END;
            end;
        }
        field(4;"Bill-to Customer No.";Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                BilltoCustomerNoChanged := xRec."Bill-to Customer No." <> "Bill-to Customer No.";
                IF BilltoCustomerNoChanged THEN
                  IF xRec."Bill-to Customer No." = '' THEN
                    InitRecord
                  ELSE BEGIN
                    IF GetHideValidationDialog OR NOT GUIALLOWED THEN
                      Confirmed := TRUE
                    ELSE
                      Confirmed := CONFIRM(ConfirmChangeQst,FALSE,BillToCustomerTxt);
                    IF Confirmed THEN BEGIN
                      SalesLine.SETRANGE("Document Type","Document Type");
                      SalesLine.SETRANGE("Document No.","No.");

                      CheckShipmentInfo(SalesLine,TRUE);
                      CheckPrepmtInfo(SalesLine);
                      CheckReturnInfo(SalesLine,TRUE);

                      SalesLine.RESET;
                    END ELSE
                      "Bill-to Customer No." := xRec."Bill-to Customer No.";
                  END;

                GetCust("Bill-to Customer No.");
                Cust.CheckBlockedCustOnDocs(Cust,"Document Type",FALSE,FALSE);
                Cust.TESTFIELD("Customer Posting Group");
                PostingSetupMgt.CheckCustPostingGroupReceivablesAccount("Customer Posting Group");
                CheckCrLimit;
                "Bill-to Customer Template Code" := '';
                "Bill-to Name" := Cust.Name;
                "Bill-to Name 2" := Cust."Name 2";
                CopyBillToCustomerAddressFieldsFromCustomer(Cust);
                IF NOT SkipBillToContact THEN
                  "Bill-to Contact" := Cust.Contact;
                "Payment Terms Code" := Cust."Payment Terms Code";
                "Prepmt. Payment Terms Code" := Cust."Payment Terms Code";

                IF "Document Type" = "Document Type"::"Credit Memo" THEN BEGIN
                  "Payment Method Code" := '';
                  IF PaymentTerms.GET("Payment Terms Code") THEN
                    IF PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN
                      "Payment Method Code" := Cust."Payment Method Code"
                END ELSE
                  "Payment Method Code" := Cust."Payment Method Code";

                GLSetup.GET;
                IF GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." THEN BEGIN
                  "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                  "VAT Country/Region Code" := Cust."Country/Region Code";
                  "VAT Registration No." := Cust."VAT Registration No.";
                  "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                END;
                "Customer Posting Group" := Cust."Customer Posting Group";
                "Currency Code" := Cust."Currency Code";
                "Customer Price Group" := Cust."Customer Price Group";
                "Prices Including VAT" := Cust."Prices Including VAT";
                "Allow Line Disc." := Cust."Allow Line Disc.";
                "Invoice Disc. Code" := Cust."Invoice Disc. Code";
                "Customer Disc. Group" := Cust."Customer Disc. Group";
                "Language Code" := Cust."Language Code";
                "Salesperson Code" := Cust."Salesperson Code";
                "Combine Shipments" := Cust."Combine Shipments";
                Reserve := Cust.Reserve;
                IF "Document Type" = "Document Type"::Order THEN
                  "Prepayment %" := Cust."Prepayment %";
                OnAfterSetFieldsBilltoCustomer(Rec,Cust);

                IF NOT BilltoCustomerNoChanged THEN
                  IF ShippedSalesLinesExist THEN BEGIN
                    TESTFIELD("Customer Disc. Group",xRec."Customer Disc. Group");
                    TESTFIELD("Currency Code",xRec."Currency Code");
                  END;

                CreateDim(
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");

                VALIDATE("Payment Terms Code");
                VALIDATE("Prepmt. Payment Terms Code");
                VALIDATE("Payment Method Code");
                VALIDATE("Currency Code");
                VALIDATE("Prepayment %");

                IF (xRec."Sell-to Customer No." = "Sell-to Customer No.") AND
                   BilltoCustomerNoChanged
                THEN BEGIN
                  RecreateSalesLines(BillToCustomerTxt);
                  BilltoCustomerNoChanged := FALSE;
                END;
                IF NOT SkipBillToContact THEN
                  UpdateBillToCont("Bill-to Customer No.");

                "Bill-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Bill-to IC Partner Code" <> '') AND ("IC Direction" = "IC Direction"::Outgoing);

                IF (xRec."Bill-to Customer No." <> '') AND (xRec."Bill-to Customer No." <> "Bill-to Customer No.") THEN
                  RecallModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId);
            end;
        }
        field(5;"Bill-to Name";Text[50])
        {
            Caption = 'Bill-to Name';
            TableRelation = Customer;
            ValidateTableRelation = false;

            trigger OnValidate();
            var
                Customer : Record "18";
            begin
                VALIDATE("Bill-to Customer No.",Customer.GetCustNo("Bill-to Name"));
            end;
        }
        field(6;"Bill-to Name 2";Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7;"Bill-to Address";Text[50])
        {
            Caption = 'Bill-to Address';

            trigger OnValidate();
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(8;"Bill-to Address 2";Text[50])
        {
            Caption = 'Bill-to Address 2';

            trigger OnValidate();
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(9;"Bill-to City";Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = IF (Bill-to Country/Region Code=CONST()) "Post Code".City
                            ELSE IF (Bill-to Country/Region Code=FILTER(<>'')) "Post Code".City WHERE (Country/Region Code=FIELD(Bill-to Country/Region Code));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                PostCode.ValidateCity(
                  "Bill-to City","Bill-to Post Code","Bill-to County","Bill-to Country/Region Code",(CurrFieldNo <> 0) AND GUIALLOWED);
                ModifyBillToCustomerAddress;
            end;
        }
        field(10;"Bill-to Contact";Text[50])
        {
            Caption = 'Bill-to Contact';

            trigger OnLookup();
            var
                Contact : Record "5050";
            begin
                LookupContact("Bill-to Customer No.","Bill-to Contact No.",Contact);
                IF PAGE.RUNMODAL(0,Contact) = ACTION::LookupOK THEN
                  VALIDATE("Bill-to Contact No.",Contact."No.");
            end;

            trigger OnValidate();
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(11;"Your Reference";Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12;"Ship-to Code";Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code WHERE (Customer No.=FIELD(Sell-to Customer No.));

            trigger OnValidate();
            var
                ShipToAddr : Record "222";
            begin
                IF ("Document Type" = "Document Type"::Order) AND
                   (xRec."Ship-to Code" <> "Ship-to Code")
                THEN BEGIN
                  SalesLine.SETRANGE("Document Type",SalesLine."Document Type"::Order);
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Purch. Order Line No.",'<>0');
                  IF NOT SalesLine.ISEMPTY THEN
                    ERROR(
                      Text006,
                      FIELDCAPTION("Ship-to Code"));
                  SalesLine.RESET;
                END;

                IF NOT IsCreditDocType THEN
                  IF "Ship-to Code" <> '' THEN BEGIN
                    IF xRec."Ship-to Code" <> '' THEN
                      BEGIN
                      GetCust("Sell-to Customer No.");
                      IF Cust."Location Code" <> '' THEN
                        VALIDATE("Location Code",Cust."Location Code");
                      "Tax Area Code" := Cust."Tax Area Code";
                    END;
                    ShipToAddr.GET("Sell-to Customer No.","Ship-to Code");
                    "Ship-to Name" := ShipToAddr.Name;
                    "Ship-to Name 2" := ShipToAddr."Name 2";
                    "Ship-to Address" := ShipToAddr.Address;
                    "Ship-to Address 2" := ShipToAddr."Address 2";
                    "Ship-to City" := ShipToAddr.City;
                    "Ship-to Post Code" := ShipToAddr."Post Code";
                    "Ship-to County" := ShipToAddr.County;
                    VALIDATE("Ship-to Country/Region Code",ShipToAddr."Country/Region Code");
                    "Ship-to Contact" := ShipToAddr.Contact;
                    "Shipment Method Code" := ShipToAddr."Shipment Method Code";
                    IF ShipToAddr."Location Code" <> '' THEN
                      VALIDATE("Location Code",ShipToAddr."Location Code");
                    "Shipping Agent Code" := ShipToAddr."Shipping Agent Code";
                    "Shipping Agent Service Code" := ShipToAddr."Shipping Agent Service Code";
                    IF ShipToAddr."Tax Area Code" <> '' THEN
                      "Tax Area Code" := ShipToAddr."Tax Area Code";
                    "Tax Liable" := ShipToAddr."Tax Liable";
                  END ELSE
                    IF "Sell-to Customer No." <> '' THEN BEGIN
                      GetCust("Sell-to Customer No.");
                      "Ship-to Name" := Cust.Name;
                      "Ship-to Name 2" := Cust."Name 2";
                      CopyShipToCustomerAddressFieldsFromCustomer(Cust);
                      "Ship-to Contact" := Cust.Contact;
                      "Shipment Method Code" := Cust."Shipment Method Code";
                      "Tax Area Code" := Cust."Tax Area Code";
                      "Tax Liable" := Cust."Tax Liable";
                      IF Cust."Location Code" <> '' THEN
                        VALIDATE("Location Code",Cust."Location Code");
                      "Shipping Agent Code" := Cust."Shipping Agent Code";
                      "Shipping Agent Service Code" := Cust."Shipping Agent Service Code";
                    END;

                GetShippingTime(FIELDNO("Ship-to Code"));

                IF (xRec."Sell-to Customer No." = "Sell-to Customer No.") AND
                   (xRec."Ship-to Code" <> "Ship-to Code")
                THEN
                  IF (xRec."VAT Country/Region Code" <> "VAT Country/Region Code") OR
                     (xRec."Tax Area Code" <> "Tax Area Code")
                  THEN
                    RecreateSalesLines(FIELDCAPTION("Ship-to Code"))
                  ELSE BEGIN
                    IF xRec."Shipping Agent Code" <> "Shipping Agent Code" THEN
                      MessageIfSalesLinesExist(FIELDCAPTION("Shipping Agent Code"));
                    IF xRec."Shipping Agent Service Code" <> "Shipping Agent Service Code" THEN
                      MessageIfSalesLinesExist(FIELDCAPTION("Shipping Agent Service Code"));
                    IF xRec."Tax Liable" <> "Tax Liable" THEN
                      VALIDATE("Tax Liable");
                  END;
            end;
        }
        field(13;"Ship-to Name";Text[50])
        {
            Caption = 'Ship-to Name';
        }
        field(14;"Ship-to Name 2";Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(15;"Ship-to Address";Text[50])
        {
            Caption = 'Ship-to Address';
        }
        field(16;"Ship-to Address 2";Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17;"Ship-to City";Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = IF (Ship-to Country/Region Code=CONST()) "Post Code".City
                            ELSE IF (Ship-to Country/Region Code=FILTER(<>'')) "Post Code".City WHERE (Country/Region Code=FIELD(Ship-to Country/Region Code));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                PostCode.ValidateCity(
                  "Ship-to City","Ship-to Post Code","Ship-to County","Ship-to Country/Region Code",(CurrFieldNo <> 0) AND GUIALLOWED);
            end;
        }
        field(18;"Ship-to Contact";Text[50])
        {
            Caption = 'Ship-to Contact';
        }
        field(19;"Order Date";Date)
        {
            AccessByPermission = TableData 110=R;
            Caption = 'Order Date';

            trigger OnValidate();
            begin
                IF ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) AND
                   NOT ("Order Date" = xRec."Order Date")
                THEN
                  PriceMessageIfSalesLinesExist(FIELDCAPTION("Order Date"));
            end;
        }
        field(20;"Posting Date";Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate();
            begin
                TestNoSeriesDate(
                  "Posting No.","Posting No. Series",
                  FIELDCAPTION("Posting No."),FIELDCAPTION("Posting No. Series"));
                TestNoSeriesDate(
                  "Prepayment No.","Prepayment No. Series",
                  FIELDCAPTION("Prepayment No."),FIELDCAPTION("Prepayment No. Series"));
                TestNoSeriesDate(
                  "Prepmt. Cr. Memo No.","Prepmt. Cr. Memo No. Series",
                  FIELDCAPTION("Prepmt. Cr. Memo No."),FIELDCAPTION("Prepmt. Cr. Memo No. Series"));

                IF "Incoming Document Entry No." = 0 THEN
                  VALIDATE("Document Date","Posting Date");

                IF ("Document Type" IN ["Document Type"::Invoice,"Document Type"::"Credit Memo"]) AND
                   NOT ("Posting Date" = xRec."Posting Date")
                THEN
                  PriceMessageIfSalesLinesExist(FIELDCAPTION("Posting Date"));

                IF "Currency Code" <> '' THEN BEGIN
                  UpdateCurrencyFactor;
                  IF "Currency Factor" <> xRec."Currency Factor" THEN
                    ConfirmUpdateCurrencyFactor;
                END;

                IF "Posting Date" <> xRec."Posting Date" THEN
                  IF DeferralHeadersExist THEN
                    ConfirmUpdateDeferralDate;
                SynchronizeAsmHeader;
            end;
        }
        field(21;"Shipment Date";Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate();
            begin
                UpdateSalesLines(FIELDCAPTION("Shipment Date"),CurrFieldNo <> 0);
            end;
        }
        field(22;"Posting Description";Text[50])
        {
            Caption = 'Posting Description';
        }
        field(23;"Payment Terms Code";Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate();
            begin
                IF ("Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN BEGIN
                  PaymentTerms.GET("Payment Terms Code");
                  IF IsCreditDocType AND NOT PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN BEGIN
                    VALIDATE("Due Date","Document Date");
                    VALIDATE("Pmt. Discount Date",0D);
                    VALIDATE("Payment Discount %",0);
                  END ELSE BEGIN
                    "Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                    "Pmt. Discount Date" := CALCDATE(PaymentTerms."Discount Date Calculation","Document Date");
                    IF NOT UpdateDocumentDate THEN
                      VALIDATE("Payment Discount %",PaymentTerms."Discount %")
                  END;
                END ELSE BEGIN
                  VALIDATE("Due Date","Document Date");
                  IF NOT UpdateDocumentDate THEN BEGIN
                    VALIDATE("Pmt. Discount Date",0D);
                    VALIDATE("Payment Discount %",0);
                  END;
                END;
                IF xRec."Payment Terms Code" = "Prepmt. Payment Terms Code" THEN BEGIN
                  IF xRec."Prepayment Due Date" = 0D THEN
                    "Prepayment Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                  VALIDATE("Prepmt. Payment Terms Code","Payment Terms Code");
                END;
            end;
        }
        field(24;"Due Date";Date)
        {
            Caption = 'Due Date';
        }
        field(25;"Payment Discount %";Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate();
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date"),FIELDNO("Document Date")]) THEN
                  TESTFIELD(Status,Status::Open);
                GLSetup.GET;
                IF "Payment Discount %" < GLSetup."VAT Tolerance %" THEN
                  "VAT Base Discount %" := "Payment Discount %"
                ELSE
                  "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                VALIDATE("VAT Base Discount %");
            end;
        }
        field(26;"Pmt. Discount Date";Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27;"Shipment Method Code";Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
            end;
        }
        field(28;"Location Code";Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE (Use As In-Transit=CONST(No));

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF ("Location Code" <> xRec."Location Code") AND
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                THEN
                  MessageIfSalesLinesExist(FIELDCAPTION("Location Code"));

                UpdateShipToAddress;
                UpdateOutboundWhseHandlingTime;
            end;
        }
        field(29;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1),
                                                          Blocked=CONST(No));

            trigger OnValidate();
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(30;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2),
                                                          Blocked=CONST(No));

            trigger OnValidate();
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
        }
        field(31;"Customer Posting Group";Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        field(32;"Currency Code";Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate();
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date")]) OR ("Currency Code" <> xRec."Currency Code") THEN
                  TESTFIELD(Status,Status::Open);
                IF (CurrFieldNo <> FIELDNO("Currency Code")) AND ("Currency Code" = xRec."Currency Code") THEN
                  UpdateCurrencyFactor
                ELSE
                  IF "Currency Code" <> xRec."Currency Code" THEN BEGIN
                    UpdateCurrencyFactor;
                    RecreateSalesLines(FIELDCAPTION("Currency Code"));
                  END ELSE
                    IF "Currency Code" <> '' THEN BEGIN
                      UpdateCurrencyFactor;
                      IF "Currency Factor" <> xRec."Currency Factor" THEN
                        ConfirmUpdateCurrencyFactor;
                    END;
            end;
        }
        field(33;"Currency Factor";Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0:15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate();
            begin
                IF "Currency Factor" <> xRec."Currency Factor" THEN
                  UpdateSalesLines(FIELDCAPTION("Currency Factor"),FALSE);
            end;
        }
        field(34;"Customer Price Group";Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate();
            begin
                MessageIfSalesLinesExist(FIELDCAPTION("Customer Price Group"));
            end;
        }
        field(35;"Prices Including VAT";Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate();
            var
                SalesLine : Record "37";
                Currency : Record "4";
                RecalculatePrice : Boolean;
            begin
                TESTFIELD(Status,Status::Open);

                IF "Prices Including VAT" <> xRec."Prices Including VAT" THEN BEGIN
                  SalesLine.SETRANGE("Document Type","Document Type");
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Job Contract Entry No.",'<>%1',0);
                  IF SalesLine.FIND('-') THEN BEGIN
                    SalesLine.TESTFIELD("Job No.",'');
                    SalesLine.TESTFIELD("Job Contract Entry No.",0);
                  END;

                  SalesLine.RESET;
                  SalesLine.SETRANGE("Document Type","Document Type");
                  SalesLine.SETRANGE("Document No.","No.");
                  SalesLine.SETFILTER("Unit Price",'<>%1',0);
                  SalesLine.SETFILTER("VAT %",'<>%1',0);
                  IF SalesLine.FINDFIRST THEN BEGIN
                    RecalculatePrice :=
                      CONFIRM(
                        STRSUBSTNO(
                          Text024,
                          FIELDCAPTION("Prices Including VAT"),SalesLine.FIELDCAPTION("Unit Price")),
                        TRUE);
                    SalesLine.SetSalesHeader(Rec);

                    IF RecalculatePrice AND "Prices Including VAT" THEN
                      SalesLine.MODIFYALL(Amount,0,TRUE);

                    IF "Currency Code" = '' THEN
                      Currency.InitRoundingPrecision
                    ELSE
                      Currency.GET("Currency Code");
                    SalesLine.LOCKTABLE;
                    LOCKTABLE;
                    SalesLine.FINDSET;
                    REPEAT
                      SalesLine.TESTFIELD("Quantity Invoiced",0);
                      SalesLine.TESTFIELD("Prepmt. Amt. Inv.",0);
                      IF NOT RecalculatePrice THEN BEGIN
                        SalesLine."VAT Difference" := 0;
                        SalesLine.UpdateAmounts;
                      END ELSE
                        IF "Prices Including VAT" THEN BEGIN
                          SalesLine."Unit Price" :=
                            ROUND(
                              SalesLine."Unit Price" * (1 + (SalesLine."VAT %" / 100)),
                              Currency."Unit-Amount Rounding Precision");
                          IF SalesLine.Quantity <> 0 THEN BEGIN
                            SalesLine."Line Discount Amount" :=
                              ROUND(
                                SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                                Currency."Amount Rounding Precision");
                            SalesLine.VALIDATE("Inv. Discount Amount",
                              ROUND(
                                SalesLine."Inv. Discount Amount" * (1 + (SalesLine."VAT %" / 100)),
                                Currency."Amount Rounding Precision"));
                          END;
                        END ELSE BEGIN
                          SalesLine."Unit Price" :=
                            ROUND(
                              SalesLine."Unit Price" / (1 + (SalesLine."VAT %" / 100)),
                              Currency."Unit-Amount Rounding Precision");
                          IF SalesLine.Quantity <> 0 THEN BEGIN
                            SalesLine."Line Discount Amount" :=
                              ROUND(
                                SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                                Currency."Amount Rounding Precision");
                            SalesLine.VALIDATE("Inv. Discount Amount",
                              ROUND(
                                SalesLine."Inv. Discount Amount" / (1 + (SalesLine."VAT %" / 100)),
                                Currency."Amount Rounding Precision"));
                          END;
                        END;
                      SalesLine.MODIFY;
                    UNTIL SalesLine.NEXT = 0;
                  END;
                END;
            end;
        }
        field(37;"Invoice Disc. Code";Code[20])
        {
            AccessByPermission = TableData 19=R;
            Caption = 'Invoice Disc. Code';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Invoice Disc. Code"));
            end;
        }
        field(40;"Customer Disc. Group";Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Customer Disc. Group"));
            end;
        }
        field(41;"Language Code";Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate();
            begin
                MessageIfSalesLinesExist(FIELDCAPTION("Language Code"));
            end;
        }
        field(43;"Salesperson Code";Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = Salesperson/Purchaser;

            trigger OnValidate();
            var
                ApprovalEntry : Record "454";
            begin
                ApprovalEntry.SETRANGE("Table ID",DATABASE::"Sales Header");
                ApprovalEntry.SETRANGE("Document Type","Document Type");
                ApprovalEntry.SETRANGE("Document No.","No.");
                ApprovalEntry.SETFILTER(Status,'%1|%2',ApprovalEntry.Status::Created,ApprovalEntry.Status::Open);
                IF NOT ApprovalEntry.ISEMPTY THEN
                  ERROR(Text053,FIELDCAPTION("Salesperson Code"));

                CreateDim(
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");
            end;
        }
        field(45;"Order Class";Code[10])
        {
            Caption = 'Order Class';
        }
        field(46;Comment;Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE (Document Type=FIELD(Document Type),
                                                            No.=FIELD(No.),
                                                            Document Line No.=CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47;"No. Printed";Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(51;"On Hold";Code[3])
        {
            Caption = 'On Hold';
        }
        field(52;"Applies-to Doc. Type";Option)
        {
            Caption = 'Applies-to Doc. Type';
            OptionCaption = '" ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund"';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(53;"Applies-to Doc. No.";Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup();
            var
                GenJnlLine : Record "81";
                GenJnlApply : Codeunit "225";
                ApplyCustEntries : Page "232";
            begin
                TESTFIELD("Bal. Account No.",'');
                CustLedgEntry.SetApplyToFilters("Bill-to Customer No.","Applies-to Doc. Type","Applies-to Doc. No.",Amount);

                ApplyCustEntries.SetSales(Rec,CustLedgEntry,SalesHeader.FIELDNO("Applies-to Doc. No."));
                ApplyCustEntries.SETTABLEVIEW(CustLedgEntry);
                ApplyCustEntries.SETRECORD(CustLedgEntry);
                ApplyCustEntries.LOOKUPMODE(TRUE);
                IF ApplyCustEntries.RUNMODAL = ACTION::LookupOK THEN BEGIN
                  ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                  GenJnlApply.CheckAgainstApplnCurrency(
                    "Currency Code",CustLedgEntry."Currency Code",GenJnlLine."Account Type"::Customer,TRUE);
                  "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                  "Applies-to Doc. No." := CustLedgEntry."Document No.";
                END;
                CLEAR(ApplyCustEntries);
            end;

            trigger OnValidate();
            begin
                IF "Applies-to Doc. No." <> '' THEN
                  TESTFIELD("Bal. Account No.",'');

                IF ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND (xRec."Applies-to Doc. No." <> '') AND
                   ("Applies-to Doc. No." <> '')
                THEN BEGIN
                  CustLedgEntry.SetAmountToApply("Applies-to Doc. No.","Bill-to Customer No.");
                  CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.","Bill-to Customer No.");
                END ELSE
                  IF ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND (xRec."Applies-to Doc. No." = '') THEN
                    CustLedgEntry.SetAmountToApply("Applies-to Doc. No.","Bill-to Customer No.")
                  ELSE
                    IF ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") AND ("Applies-to Doc. No." = '') THEN
                      CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.","Bill-to Customer No.");
            end;
        }
        field(55;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account";

            trigger OnValidate();
            begin
                IF "Bal. Account No." <> '' THEN
                  CASE "Bal. Account Type" OF
                    "Bal. Account Type"::"G/L Account":
                      BEGIN
                        GLAcc.GET("Bal. Account No.");
                        GLAcc.CheckGLAcc;
                        GLAcc.TESTFIELD("Direct Posting",TRUE);
                      END;
                    "Bal. Account Type"::"Bank Account":
                      BEGIN
                        BankAcc.GET("Bal. Account No.");
                        BankAcc.TESTFIELD(Blocked,FALSE);
                        BankAcc.TESTFIELD("Currency Code","Currency Code");
                      END;
                  END;
            end;
        }
        field(56;"Recalculate Invoice Disc.";Boolean)
        {
            CalcFormula = Exist("Sales Line" WHERE (Document Type=FIELD(Document Type),
                                                    Document No.=FIELD(No.),
                                                    Recalculate Invoice Disc.=CONST(Yes)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57;Ship;Boolean)
        {
            Caption = 'Ship';
            Editable = false;
        }
        field(58;Invoice;Boolean)
        {
            Caption = 'Invoice';
        }
        field(59;"Print Posted Documents";Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        field(60;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line".Amount WHERE (Document Type=FIELD(Document Type),
                                                         Document No.=FIELD(No.)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61;"Amount Including VAT";Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Amount Including VAT" WHERE (Document Type=FIELD(Document Type),
                                                                         Document No.=FIELD(No.)));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62;"Shipping No.";Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(63;"Posting No.";Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64;"Last Shipping No.";Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Sales Shipment Header";
        }
        field(65;"Last Posting No.";Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(66;"Prepayment No.";Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(67;"Last Prepayment No.";Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        field(68;"Prepmt. Cr. Memo No.";Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(69;"Last Prepmt. Cr. Memo No.";Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Cr.Memo Header";
        }
        field(70;"VAT Registration No.";Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate();
            var
                Customer : Record "18";
                VATRegistrationLog : Record "249";
                VATRegistrationNoFormat : Record "381";
                VATRegistrationLogMgt : Codeunit "249";
                ResultRecRef : RecordRef;
                ApplicableCountryCode : Code[10];
            begin
                "VAT Registration No." := UPPERCASE("VAT Registration No.");
                IF "VAT Registration No." = xRec."VAT Registration No." THEN
                  EXIT;

                IF NOT Customer.GET("Sell-to Customer No.") THEN
                  EXIT;

                IF "VAT Registration No." = Customer."VAT Registration No." THEN
                  EXIT;

                IF NOT VATRegistrationNoFormat.Test("VAT Registration No.",Customer."Country/Region Code",Customer."No.",DATABASE::Customer) THEN
                  EXIT;

                Customer."VAT Registration No." := "VAT Registration No.";
                ApplicableCountryCode := Customer."Country/Region Code";
                IF ApplicableCountryCode = '' THEN
                  ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";

                VATRegistrationLogMgt.CheckVIESForVATNo(ResultRecRef,VATRegistrationLog,Customer,Customer."No.",
                  ApplicableCountryCode,VATRegistrationLog."Account Type"::Customer);

                IF VATRegistrationLog.Status = VATRegistrationLog.Status::Valid THEN BEGIN
                  MESSAGE(ValidVATNoMsg);
                  Customer.MODIFY(TRUE);
                END ELSE
                  MESSAGE(InvalidVatRegNoMsg);
            end;
        }
        field(71;"Combine Shipments";Boolean)
        {
            Caption = 'Combine Shipments';
        }
        field(73;"Reason Code";Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(74;"Gen. Bus. Posting Group";Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" THEN BEGIN
                  IF GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp,"Gen. Bus. Posting Group") THEN
                    "VAT Bus. Posting Group" := GenBusPostingGrp."Def. VAT Bus. Posting Group";
                  RecreateSalesLines(FIELDCAPTION("Gen. Bus. Posting Group"));
                END;
            end;
        }
        field(75;"EU 3-Party Trade";Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(76;"Transaction Type";Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";

            trigger OnValidate();
            begin
                UpdateSalesLines(FIELDCAPTION("Transaction Type"),FALSE);
            end;
        }
        field(77;"Transport Method";Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate();
            begin
                UpdateSalesLines(FIELDCAPTION("Transport Method"),FALSE);
            end;
        }
        field(78;"VAT Country/Region Code";Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = Country/Region;
        }
        field(79;"Sell-to Customer Name";Text[50])
        {
            Caption = 'Sell-to Customer Name';
            TableRelation = Customer;
            ValidateTableRelation = false;

            trigger OnValidate();
            var
                Customer : Record "18";
                IdentityManagement : Codeunit "9801";
            begin
                IF NOT IdentityManagement.IsInvAppId THEN
                  VALIDATE("Sell-to Customer No.",Customer.GetCustNo("Sell-to Customer Name"));
                GetShippingTime(FIELDNO("Sell-to Customer Name"));
            end;
        }
        field(80;"Sell-to Customer Name 2";Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
        }
        field(81;"Sell-to Address";Text[50])
        {
            Caption = 'Sell-to Address';

            trigger OnValidate();
            begin
                UpdateShipToAddressFromSellToAddress(FIELDNO("Ship-to Address"));
                ModifyCustomerAddress;
            end;
        }
        field(82;"Sell-to Address 2";Text[50])
        {
            Caption = 'Sell-to Address 2';

            trigger OnValidate();
            begin
                UpdateShipToAddressFromSellToAddress(FIELDNO("Ship-to Address 2"));
                ModifyCustomerAddress;
            end;
        }
        field(83;"Sell-to City";Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = IF (Sell-to Country/Region Code=CONST()) "Post Code".City
                            ELSE IF (Sell-to Country/Region Code=FILTER(<>'')) "Post Code".City WHERE (Country/Region Code=FIELD(Sell-to Country/Region Code));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                PostCode.ValidateCity(
                  "Sell-to City","Sell-to Post Code","Sell-to County","Sell-to Country/Region Code",(CurrFieldNo <> 0) AND GUIALLOWED);
                UpdateShipToAddressFromSellToAddress(FIELDNO("Ship-to City"));
                ModifyCustomerAddress;
            end;
        }
        field(84;"Sell-to Contact";Text[50])
        {
            Caption = 'Sell-to Contact';

            trigger OnLookup();
            var
                Contact : Record "5050";
            begin
                IF "Sell-to Customer No." = '' THEN
                  EXIT;

                LookupContact("Sell-to Customer No.","Sell-to Contact No.",Contact);
                IF PAGE.RUNMODAL(0,Contact) = ACTION::LookupOK THEN
                  VALIDATE("Sell-to Contact No.",Contact."No.");
            end;

            trigger OnValidate();
            begin
                ModifyCustomerAddress;
            end;
        }
        field(85;"Bill-to Post Code";Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                PostCode.ValidatePostCode(
                  "Bill-to City","Bill-to Post Code","Bill-to County","Bill-to Country/Region Code",(CurrFieldNo <> 0) AND GUIALLOWED);
                ModifyBillToCustomerAddress;
            end;
        }
        field(86;"Bill-to County";Text[30])
        {
            Caption = 'Bill-to County';

            trigger OnValidate();
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(87;"Bill-to Country/Region Code";Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = Country/Region;

            trigger OnValidate();
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(88;"Sell-to Post Code";Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = IF (Sell-to Country/Region Code=CONST()) "Post Code"
                            ELSE IF (Sell-to Country/Region Code=FILTER(<>'')) "Post Code" WHERE (Country/Region Code=FIELD(Sell-to Country/Region Code));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                PostCode.ValidatePostCode(
                  "Sell-to City","Sell-to Post Code","Sell-to County","Sell-to Country/Region Code",(CurrFieldNo <> 0) AND GUIALLOWED);
                UpdateShipToAddressFromSellToAddress(FIELDNO("Ship-to Post Code"));
                ModifyCustomerAddress;
            end;
        }
        field(89;"Sell-to County";Text[30])
        {
            Caption = 'Sell-to County';

            trigger OnValidate();
            begin
                UpdateShipToAddressFromSellToAddress(FIELDNO("Ship-to County"));
                ModifyCustomerAddress;
            end;
        }
        field(90;"Sell-to Country/Region Code";Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = Country/Region;

            trigger OnValidate();
            begin
                UpdateShipToAddressFromSellToAddress(FIELDNO("Ship-to Country/Region Code"));
                ModifyCustomerAddress;
            end;
        }
        field(91;"Ship-to Post Code";Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = IF (Ship-to Country/Region Code=CONST()) "Post Code"
                            ELSE IF (Ship-to Country/Region Code=FILTER(<>'')) "Post Code" WHERE (Country/Region Code=FIELD(Ship-to Country/Region Code));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                PostCode.ValidatePostCode(
                  "Ship-to City","Ship-to Post Code","Ship-to County","Ship-to Country/Region Code",(CurrFieldNo <> 0) AND GUIALLOWED);
            end;
        }
        field(92;"Ship-to County";Text[30])
        {
            Caption = 'Ship-to County';
        }
        field(93;"Ship-to Country/Region Code";Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = Country/Region;
        }
        field(94;"Bal. Account Type";Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
        field(97;"Exit Point";Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";

            trigger OnValidate();
            begin
                UpdateSalesLines(FIELDCAPTION("Exit Point"),FALSE);
            end;
        }
        field(98;Correction;Boolean)
        {
            Caption = 'Correction';
        }
        field(99;"Document Date";Date)
        {
            Caption = 'Document Date';

            trigger OnValidate();
            begin
                IF xRec."Document Date" <> "Document Date" THEN
                  UpdateDocumentDate := TRUE;
                VALIDATE("Payment Terms Code");
                VALIDATE("Prepmt. Payment Terms Code");
            end;
        }
        field(100;"External Document No.";Code[35])
        {
            Caption = 'External Document No.';
        }
        field(101;"Area";Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate();
            begin
                UpdateSalesLines(FIELDCAPTION(Area),FALSE);
            end;
        }
        field(102;"Transaction Specification";Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate();
            begin
                UpdateSalesLines(FIELDCAPTION("Transaction Specification"),FALSE);
            end;
        }
        field(104;"Payment Method Code";Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate();
            var
                SEPADirectDebitMandate : Record "1230";
            begin
                PaymentMethod.INIT;
                IF "Payment Method Code" <> '' THEN
                  PaymentMethod.GET("Payment Method Code");
                IF PaymentMethod."Direct Debit" THEN BEGIN
                  "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.","Due Date");
                  IF "Payment Terms Code" = '' THEN
                    "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
                END ELSE
                  "Direct Debit Mandate ID" := '';
                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                IF "Bal. Account No." <> '' THEN BEGIN
                  TESTFIELD("Applies-to Doc. No.",'');
                  TESTFIELD("Applies-to ID",'');
                  CLEAR("Payment Service Set ID");
                END;
            end;
        }
        field(105;"Shipping Agent Code";Code[10])
        {
            AccessByPermission = TableData 5790=R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF xRec."Shipping Agent Code" = "Shipping Agent Code" THEN
                  EXIT;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FIELDNO("Shipping Agent Code"));
                UpdateSalesLines(FIELDCAPTION("Shipping Agent Code"),CurrFieldNo <> 0);
            end;
        }
        field(106;"Package Tracking No.";Text[30])
        {
            Caption = 'Package Tracking No.';
        }
        field(107;"No. Series";Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108;"Posting No. Series";Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup();
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  TestNoSeries;
                  IF NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode,"Posting No. Series") THEN
                    VALIDATE("Posting No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate();
            begin
                IF "Posting No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  TestNoSeries;
                  NoSeriesMgt.TestSeries(GetPostingNoSeriesCode,"Posting No. Series");
                END;
                TESTFIELD("Posting No.",'');
            end;
        }
        field(109;"Shipping No. Series";Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";

            trigger OnLookup();
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Shipment Nos.");
                  IF NoSeriesMgt.LookupSeries(SalesSetup."Posted Shipment Nos.","Shipping No. Series") THEN
                    VALIDATE("Shipping No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate();
            begin
                IF "Shipping No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Shipment Nos.");
                  NoSeriesMgt.TestSeries(SalesSetup."Posted Shipment Nos.","Shipping No. Series");
                END;
                TESTFIELD("Shipping No.",'');
            end;
        }
        field(114;"Tax Area Code";Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
            ValidateTableRelation = false;

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                ValidateTaxAreaCode;
                MessageIfSalesLinesExist(FIELDCAPTION("Tax Area Code"));
            end;
        }
        field(115;"Tax Liable";Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Tax Liable"));
            end;
        }
        field(116;"VAT Bus. Posting Group";Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" THEN
                  RecreateSalesLines(FIELDCAPTION("VAT Bus. Posting Group"));
            end;
        }
        field(117;Reserve;Option)
        {
            AccessByPermission = TableData 27=R;
            Caption = 'Reserve';
            InitValue = Optional;
            OptionCaption = 'Never,Optional,Always';
            OptionMembers = Never,Optional,Always;
        }
        field(118;"Applies-to ID";Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate();
            var
                TempCustLedgEntry : Record "21" temporary;
                CustEntrySetApplID : Codeunit "101";
            begin
                IF "Applies-to ID" <> '' THEN
                  TESTFIELD("Bal. Account No.",'');
                IF ("Applies-to ID" <> xRec."Applies-to ID") AND (xRec."Applies-to ID" <> '') THEN BEGIN
                  CustLedgEntry.SETCURRENTKEY("Customer No.",Open);
                  CustLedgEntry.SETRANGE("Customer No.","Bill-to Customer No.");
                  CustLedgEntry.SETRANGE(Open,TRUE);
                  CustLedgEntry.SETRANGE("Applies-to ID",xRec."Applies-to ID");
                  IF CustLedgEntry.FINDFIRST THEN
                    CustEntrySetApplID.SetApplId(CustLedgEntry,TempCustLedgEntry,'');
                  CustLedgEntry.RESET;
                END;
            end;
        }
        field(119;"VAT Base Discount %";Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate();
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date"),FIELDNO("Document Date")]) THEN
                  TESTFIELD(Status,Status::Open);
                GLSetup.GET;
                IF "VAT Base Discount %" > GLSetup."VAT Tolerance %" THEN
                  ERROR(
                    Text007,
                    FIELDCAPTION("VAT Base Discount %"),
                    GLSetup.FIELDCAPTION("VAT Tolerance %"),
                    GLSetup.TABLECAPTION);

                IF ("VAT Base Discount %" = xRec."VAT Base Discount %") AND
                   (CurrFieldNo <> 0)
                THEN
                  EXIT;

                SalesLine.SETRANGE("Document Type","Document Type");
                SalesLine.SETRANGE("Document No.","No.");
                SalesLine.SETFILTER(Type,'<>%1',SalesLine.Type::" ");
                SalesLine.SETFILTER(Quantity,'<>0');
                SalesLine.LOCKTABLE;
                LOCKTABLE;
                IF SalesLine.FINDSET THEN BEGIN
                  MODIFY;
                  REPEAT
                    IF (SalesLine."Quantity Invoiced" <> SalesLine.Quantity) OR
                       ("Shipping Advice" <> "Shipping Advice"::Partial) OR
                       (SalesLine.Type <> SalesLine.Type::"Charge (Item)") OR
                       (CurrFieldNo <> 0)
                    THEN BEGIN
                      SalesLine.UpdateAmounts;
                      SalesLine.MODIFY;
                    END;
                  UNTIL SalesLine.NEXT = 0;
                END;
                SalesLine.RESET;
            end;
        }
        field(120;Status;Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval,Pending Prepayment';
            OptionMembers = Open,Released,"Pending Approval","Pending Prepayment";
        }
        field(121;"Invoice Discount Calculation";Option)
        {
            Caption = 'Invoice Discount Calculation';
            Editable = false;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122;"Invoice Discount Value";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            Editable = false;
        }
        field(123;"Send IC Document";Boolean)
        {
            Caption = 'Send IC Document';

            trigger OnValidate();
            begin
                IF "Send IC Document" THEN BEGIN
                  IF "Bill-to IC Partner Code" = '' THEN
                    TESTFIELD("Sell-to IC Partner Code");
                  TESTFIELD("IC Direction","IC Direction"::Outgoing);
                END;
            end;
        }
        field(124;"IC Status";Option)
        {
            Caption = 'IC Status';
            OptionCaption = 'New,Pending,Sent';
            OptionMembers = New,Pending,Sent;
        }
        field(125;"Sell-to IC Partner Code";Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126;"Bill-to IC Partner Code";Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(129;"IC Direction";Option)
        {
            Caption = 'IC Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;

            trigger OnValidate();
            begin
                IF "IC Direction" = "IC Direction"::Incoming THEN
                  "Send IC Document" := FALSE;
            end;
        }
        field(130;"Prepayment %";Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate();
            begin
                IF xRec."Prepayment %" <> "Prepayment %" THEN
                  UpdateSalesLines(FIELDCAPTION("Prepayment %"),CurrFieldNo <> 0);
            end;
        }
        field(131;"Prepayment No. Series";Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";

            trigger OnLookup();
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Inv. Nos.");
                  IF NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode,"Prepayment No. Series") THEN
                    VALIDATE("Prepayment No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate();
            begin
                IF "Prepayment No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Inv. Nos.");
                  NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode,"Prepayment No. Series");
                END;
                TESTFIELD("Prepayment No.",'');
            end;
        }
        field(132;"Compress Prepayment";Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(133;"Prepayment Due Date";Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(134;"Prepmt. Cr. Memo No. Series";Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";

            trigger OnLookup();
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Cr. Memo Nos.");
                  IF NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode,"Prepmt. Cr. Memo No. Series") THEN
                    VALIDATE("Prepmt. Cr. Memo No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate();
            begin
                IF "Prepmt. Cr. Memo No." <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Prepmt. Cr. Memo Nos.");
                  NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode,"Prepmt. Cr. Memo No. Series");
                END;
                TESTFIELD("Prepmt. Cr. Memo No.",'');
            end;
        }
        field(135;"Prepmt. Posting Description";Text[50])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(138;"Prepmt. Pmt. Discount Date";Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(139;"Prepmt. Payment Terms Code";Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate();
            var
                PaymentTerms : Record "3";
            begin
                IF ("Prepmt. Payment Terms Code" <> '') AND ("Document Date" <> 0D) THEN BEGIN
                  PaymentTerms.GET("Prepmt. Payment Terms Code");
                  IF IsCreditDocType AND NOT PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" THEN BEGIN
                    VALIDATE("Prepayment Due Date","Document Date");
                    VALIDATE("Prepmt. Pmt. Discount Date",0D);
                    VALIDATE("Prepmt. Payment Discount %",0);
                  END ELSE BEGIN
                    "Prepayment Due Date" := CALCDATE(PaymentTerms."Due Date Calculation","Document Date");
                    "Prepmt. Pmt. Discount Date" := CALCDATE(PaymentTerms."Discount Date Calculation","Document Date");
                    IF NOT UpdateDocumentDate THEN
                      VALIDATE("Prepmt. Payment Discount %",PaymentTerms."Discount %")
                  END;
                END ELSE BEGIN
                  VALIDATE("Prepayment Due Date","Document Date");
                  IF NOT UpdateDocumentDate THEN BEGIN
                    VALIDATE("Prepmt. Pmt. Discount Date",0D);
                    VALIDATE("Prepmt. Payment Discount %",0);
                  END;
                END;
            end;
        }
        field(140;"Prepmt. Payment Discount %";Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0:5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate();
            begin
                IF NOT (CurrFieldNo IN [0,FIELDNO("Posting Date"),FIELDNO("Document Date")]) THEN
                  TESTFIELD(Status,Status::Open);
                GLSetup.GET;
                IF "Payment Discount %" < GLSetup."VAT Tolerance %" THEN
                  "VAT Base Discount %" := "Payment Discount %"
                ELSE
                  "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                VALIDATE("VAT Base Discount %");
            end;
        }
        field(151;"Quote No.";Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(152;"Quote Valid Until Date";Date)
        {
            Caption = 'Quote Valid Until Date';

            trigger OnValidate();
            begin
                IF ("Quote Valid Until Date" <> 0D) AND ("Quote Valid Until Date" < WORKDATE) THEN
                  "Quote Valid Until Date" := WORKDATE;
            end;
        }
        field(153;"Quote Sent to Customer";DateTime)
        {
            Caption = 'Quote Sent to Customer';
            Editable = false;
        }
        field(154;"Quote Accepted";Boolean)
        {
            Caption = 'Quote Accepted';

            trigger OnValidate();
            begin
                IF "Quote Accepted" THEN BEGIN
                  "Quote Accepted Date" := WORKDATE;
                  OnAfterSalesQuoteAccepted(Rec);
                END ELSE
                  "Quote Accepted Date" := 0D;
            end;
        }
        field(155;"Quote Accepted Date";Date)
        {
            Caption = 'Quote Accepted Date';
            Editable = false;
        }
        field(160;"Job Queue Status";Option)
        {
            Caption = 'Job Queue Status';
            Editable = false;
            OptionCaption = '" ,Scheduled for Posting,Error,Posting"';
            OptionMembers = " ","Scheduled for Posting",Error,Posting;

            trigger OnLookup();
            var
                JobQueueEntry : Record "472";
            begin
                IF "Job Queue Status" = "Job Queue Status"::" " THEN
                  EXIT;
                JobQueueEntry.ShowStatusMsg("Job Queue Entry ID");
            end;
        }
        field(161;"Job Queue Entry ID";Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(165;"Incoming Document Entry No.";Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate();
            var
                IncomingDocument : Record "130";
            begin
                IF "Incoming Document Entry No." = xRec."Incoming Document Entry No." THEN
                  EXIT;
                IF "Incoming Document Entry No." = 0 THEN
                  IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                ELSE
                  IncomingDocument.SetSalesDoc(Rec);
            end;
        }
        field(166;"Last Email Sent Time";DateTime)
        {
            CalcFormula = Max("O365 Document Sent History"."Created Date-Time" WHERE (Document Type=FIELD(Document Type),
                                                                                      Document No.=FIELD(No.),
                                                                                      Posted=CONST(No)));
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
        }
        field(167;"Last Email Sent Status";Option)
        {
            CalcFormula = Lookup("O365 Document Sent History"."Job Last Status" WHERE (Document Type=FIELD(Document Type),
                                                                                       Document No.=FIELD(No.),
                                                                                       Posted=CONST(No),
                                                                                       Created Date-Time=FIELD(Last Email Sent Time)));
            Caption = 'Last Email Sent Status';
            FieldClass = FlowField;
            OptionCaption = 'Not Sent,In Process,Finished,Error';
            OptionMembers = "Not Sent","In Process",Finished,Error;
        }
        field(168;"Sent as Email";Boolean)
        {
            CalcFormula = Exist("O365 Document Sent History" WHERE (Document Type=FIELD(Document Type),
                                                                    Document No.=FIELD(No.),
                                                                    Posted=CONST(No),
                                                                    Job Last Status=CONST(Finished)));
            Caption = 'Sent as Email';
            FieldClass = FlowField;
        }
        field(169;"Last Email Notif Cleared";Boolean)
        {
            CalcFormula = Lookup("O365 Document Sent History".NotificationCleared WHERE (Document Type=FIELD(Document Type),
                                                                                         Document No.=FIELD(No.),
                                                                                         Posted=CONST(No),
                                                                                         Created Date-Time=FIELD(Last Email Sent Time)));
            Caption = 'Last Email Notif Cleared';
            FieldClass = FlowField;
        }
        field(200;"Work Description";BLOB)
        {
            Caption = 'Work Description';
        }
        field(300;"Amt. Ship. Not Inv. (LCY)";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Shipped Not Invoiced (LCY)" WHERE (Document No.=FIELD(No.)));
            Caption = 'Amount Shipped Not Invoiced (LCY) Incl. VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(301;"Amt. Ship. Not Inv. (LCY) Base";Decimal)
        {
            CalcFormula = Sum("Sales Line"."Shipped Not Inv. (LCY) No VAT" WHERE (Document No.=FIELD(No.)));
            Caption = 'Amount Shipped Not Invoiced (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(480;"Dimension Set ID";Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup();
            begin
                ShowDocDim;
            end;

            trigger OnValidate();
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID","Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
            end;
        }
        field(600;"Payment Service Set ID";Integer)
        {
            Caption = 'Payment Service Set ID';
        }
        field(1200;"Direct Debit Mandate ID";Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" WHERE (Customer No.=FIELD(Bill-to Customer No.),
                                                               Closed=CONST(No),
                                                               Blocked=CONST(No));
        }
        field(1305;"Invoice Discount Amount";Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Inv. Discount Amount" WHERE (Document No.=FIELD(No.),
                                                                         Document Type=FIELD(Document Type)));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5043;"No. of Archived Versions";Integer)
        {
            CalcFormula = Max("Sales Header Archive"."Version No." WHERE (Document Type=FIELD(Document Type),
                                                                          No.=FIELD(No.),
                                                                          Doc. No. Occurrence=FIELD(Doc. No. Occurrence)));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5048;"Doc. No. Occurrence";Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5050;"Campaign No.";Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate();
            begin
                CreateDim(
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");
            end;
        }
        field(5051;"Sell-to Customer Template Code";Code[10])
        {
            Caption = 'Sell-to Customer Template Code';
            TableRelation = "Customer Template";

            trigger OnValidate();
            var
                SellToCustTemplate : Record "5105";
            begin
                TESTFIELD("Document Type","Document Type"::Quote);
                TESTFIELD(Status,Status::Open);

                IF NOT InsertMode AND
                   ("Sell-to Customer Template Code" <> xRec."Sell-to Customer Template Code") AND
                   (xRec."Sell-to Customer Template Code" <> '')
                THEN BEGIN
                  IF GetHideValidationDialog THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(ConfirmChangeQst,FALSE,FIELDCAPTION("Sell-to Customer Template Code"));
                  IF Confirmed THEN BEGIN
                    IF InitFromTemplate("Sell-to Customer Template Code",FIELDCAPTION("Sell-to Customer Template Code")) THEN
                      EXIT
                  END ELSE BEGIN
                    "Sell-to Customer Template Code" := xRec."Sell-to Customer Template Code";
                    EXIT;
                  END;
                END;

                IF SellToCustTemplate.GET("Sell-to Customer Template Code") THEN BEGIN
                  SellToCustTemplate.TESTFIELD("Gen. Bus. Posting Group");
                  "Gen. Bus. Posting Group" := SellToCustTemplate."Gen. Bus. Posting Group";
                  "VAT Bus. Posting Group" := SellToCustTemplate."VAT Bus. Posting Group";
                  IF "Bill-to Customer No." = '' THEN
                    VALIDATE("Bill-to Customer Template Code","Sell-to Customer Template Code");
                END;

                IF NOT InsertMode AND
                   ((xRec."Sell-to Customer Template Code" <> "Sell-to Customer Template Code") OR
                    (xRec."Currency Code" <> "Currency Code"))
                THEN
                  RecreateSalesLines(FIELDCAPTION("Sell-to Customer Template Code"));
            end;
        }
        field(5052;"Sell-to Contact No.";Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup();
            var
                Cont : Record "5050";
                ContBusinessRelation : Record "5054";
            begin
                IF "Sell-to Customer No." <> '' THEN
                  IF Cont.GET("Sell-to Contact No.") THEN
                    Cont.SETRANGE("Company No.",Cont."Company No.")
                  ELSE
                    IF ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer,"Sell-to Customer No.") THEN
                      Cont.SETRANGE("Company No.",ContBusinessRelation."Contact No.")
                    ELSE
                      Cont.SETRANGE("No.",'');

                IF "Sell-to Contact No." <> '' THEN
                  IF Cont.GET("Sell-to Contact No.") THEN ;
                IF PAGE.RUNMODAL(0,Cont) = ACTION::LookupOK THEN BEGIN
                  xRec := Rec;
                  VALIDATE("Sell-to Contact No.",Cont."No.");
                END;
            end;

            trigger OnValidate();
            var
                ContBusinessRelation : Record "5054";
                Cont : Record "5050";
                Opportunity : Record "5092";
            begin
                TESTFIELD(Status,Status::Open);

                IF ("Sell-to Contact No." <> xRec."Sell-to Contact No.") AND
                   (xRec."Sell-to Contact No." <> '')
                THEN BEGIN
                  IF ("Sell-to Contact No." = '') AND ("Opportunity No." <> '') THEN
                    ERROR(Text049,FIELDCAPTION("Sell-to Contact No."));
                  IF GetHideValidationDialog OR NOT GUIALLOWED THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(ConfirmChangeQst,FALSE,FIELDCAPTION("Sell-to Contact No."));
                  IF Confirmed THEN BEGIN
                    IF InitFromContact("Sell-to Contact No.","Sell-to Customer No.",FIELDCAPTION("Sell-to Contact No.")) THEN
                      EXIT;
                    IF "Opportunity No." <> '' THEN BEGIN
                      Opportunity.GET("Opportunity No.");
                      IF Opportunity."Contact No." <> "Sell-to Contact No." THEN BEGIN
                        MODIFY;
                        Opportunity.VALIDATE("Contact No.","Sell-to Contact No.");
                        Opportunity.MODIFY;
                      END
                    END;
                  END ELSE BEGIN
                    Rec := xRec;
                    EXIT;
                  END;
                END;

                IF ("Sell-to Customer No." <> '') AND ("Sell-to Contact No." <> '') THEN BEGIN
                  Cont.GET("Sell-to Contact No.");
                  IF ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer,"Sell-to Customer No.") THEN
                    IF (ContBusinessRelation."Contact No." <> Cont."Company No.") AND (ContBusinessRelation."Contact No." <> Cont."No.") THEN
                      ERROR(Text038,Cont."No.",Cont.Name,"Sell-to Customer No.");
                END;

                IF "Sell-to Contact No." <> '' THEN
                  IF Cont.GET("Sell-to Contact No.") THEN
                    IF ("Salesperson Code" = '') AND (Cont."Salesperson Code" <> '') THEN
                      VALIDATE("Salesperson Code",Cont."Salesperson Code");

                UpdateSellToCust("Sell-to Contact No.");
                UpdateSellToCustTemplateCode;
                UpdateShipToContact;
            end;
        }
        field(5053;"Bill-to Contact No.";Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup();
            var
                Cont : Record "5050";
                ContBusinessRelation : Record "5054";
            begin
                IF "Bill-to Customer No." <> '' THEN
                  IF Cont.GET("Bill-to Contact No.") THEN
                    Cont.SETRANGE("Company No.",Cont."Company No.")
                  ELSE
                    IF ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer,"Bill-to Customer No.") THEN
                      Cont.SETRANGE("Company No.",ContBusinessRelation."Contact No.")
                    ELSE
                      Cont.SETRANGE("No.",'');

                IF "Bill-to Contact No." <> '' THEN
                  IF Cont.GET("Bill-to Contact No.") THEN ;
                IF PAGE.RUNMODAL(0,Cont) = ACTION::LookupOK THEN BEGIN
                  xRec := Rec;
                  VALIDATE("Bill-to Contact No.",Cont."No.");
                END;
            end;

            trigger OnValidate();
            var
                ContBusinessRelation : Record "5054";
                Cont : Record "5050";
            begin
                TESTFIELD(Status,Status::Open);

                IF ("Bill-to Contact No." <> xRec."Bill-to Contact No.") AND
                   (xRec."Bill-to Contact No." <> '')
                THEN BEGIN
                  IF GetHideValidationDialog OR (NOT GUIALLOWED) THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(ConfirmChangeQst,FALSE,FIELDCAPTION("Bill-to Contact No."));
                  IF Confirmed THEN BEGIN
                    IF InitFromContact("Bill-to Contact No.","Bill-to Customer No.",FIELDCAPTION("Bill-to Contact No.")) THEN
                      EXIT;
                  END ELSE BEGIN
                    "Bill-to Contact No." := xRec."Bill-to Contact No.";
                    EXIT;
                  END;
                END;

                IF ("Bill-to Customer No." <> '') AND ("Bill-to Contact No." <> '') THEN BEGIN
                  Cont.GET("Bill-to Contact No.");
                  IF ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer,"Bill-to Customer No.") THEN
                    IF (ContBusinessRelation."Contact No." <> Cont."Company No.") AND (ContBusinessRelation."Contact No." <> Cont."No.") THEN
                      ERROR(Text038,Cont."No.",Cont.Name,"Bill-to Customer No.");
                END;

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5054;"Bill-to Customer Template Code";Code[10])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Template";

            trigger OnValidate();
            var
                BillToCustTemplate : Record "5105";
            begin
                TESTFIELD("Document Type","Document Type"::Quote);
                TESTFIELD(Status,Status::Open);

                IF NOT InsertMode AND
                   ("Bill-to Customer Template Code" <> xRec."Bill-to Customer Template Code") AND
                   (xRec."Bill-to Customer Template Code" <> '')
                THEN BEGIN
                  IF GetHideValidationDialog THEN
                    Confirmed := TRUE
                  ELSE
                    Confirmed := CONFIRM(ConfirmChangeQst,FALSE,FIELDCAPTION("Bill-to Customer Template Code"));
                  IF Confirmed THEN BEGIN
                    IF InitFromTemplate("Bill-to Customer Template Code",FIELDCAPTION("Bill-to Customer Template Code")) THEN
                      EXIT
                  END ELSE BEGIN
                    "Bill-to Customer Template Code" := xRec."Bill-to Customer Template Code";
                    EXIT;
                  END;
                END;

                VALIDATE("Ship-to Code",'');
                IF BillToCustTemplate.GET("Bill-to Customer Template Code") THEN BEGIN
                  BillToCustTemplate.TESTFIELD("Customer Posting Group");
                  "Customer Posting Group" := BillToCustTemplate."Customer Posting Group";
                  "Invoice Disc. Code" := BillToCustTemplate."Invoice Disc. Code";
                  "Customer Price Group" := BillToCustTemplate."Customer Price Group";
                  "Customer Disc. Group" := BillToCustTemplate."Customer Disc. Group";
                  "Allow Line Disc." := BillToCustTemplate."Allow Line Disc.";
                  VALIDATE("Payment Terms Code",BillToCustTemplate."Payment Terms Code");
                  VALIDATE("Payment Method Code",BillToCustTemplate."Payment Method Code");
                  "Prices Including VAT" := BillToCustTemplate."Prices Including VAT";
                  "Shipment Method Code" := BillToCustTemplate."Shipment Method Code";
                END;

                CreateDim(
                  DATABASE::"Customer Template","Bill-to Customer Template Code",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Responsibility Center","Responsibility Center");

                IF NOT InsertMode AND
                   (xRec."Sell-to Customer Template Code" = "Sell-to Customer Template Code") AND
                   (xRec."Bill-to Customer Template Code" <> "Bill-to Customer Template Code")
                THEN
                  RecreateSalesLines(FIELDCAPTION("Bill-to Customer Template Code"));
            end;
        }
        field(5055;"Opportunity No.";Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = IF (Document Type=FILTER(<>Order)) Opportunity.No. WHERE (Contact No.=FIELD(Sell-to Contact No.),
                                                                                      Closed=CONST(No))
                                                                                      ELSE IF (Document Type=CONST(Order)) Opportunity.No. WHERE (Contact No.=FIELD(Sell-to Contact No.),
                                                                                                                                                  Sales Document No.=FIELD(No.),
                                                                                                                                                  Sales Document Type=CONST(Order));

            trigger OnValidate();
            begin
                LinkSalesDocWithOpportunity(xRec."Opportunity No.");
            end;
        }
        field(5700;"Responsibility Center";Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF NOT UserSetupMgt.CheckRespCenter(0,"Responsibility Center") THEN
                  ERROR(
                    Text027,
                    RespCenter.TABLECAPTION,UserSetupMgt.GetSalesFilter);

                "Location Code" := UserSetupMgt.GetLocation(0,'',"Responsibility Center");
                UpdateOutboundWhseHandlingTime;
                UpdateShipToAddress;

                CreateDim(
                  DATABASE::"Responsibility Center","Responsibility Center",
                  DATABASE::Customer,"Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser","Salesperson Code",
                  DATABASE::Campaign,"Campaign No.",
                  DATABASE::"Customer Template","Bill-to Customer Template Code");

                IF xRec."Responsibility Center" <> "Responsibility Center" THEN BEGIN
                  RecreateSalesLines(FIELDCAPTION("Responsibility Center"));
                  "Assigned User ID" := '';
                END;
            end;
        }
        field(5750;"Shipping Advice";Option)
        {
            AccessByPermission = TableData 110=R;
            Caption = 'Shipping Advice';
            OptionCaption = 'Partial,Complete';
            OptionMembers = Partial,Complete;

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF InventoryPickConflict("Document Type","No.","Shipping Advice") THEN
                  ERROR(Text066,FIELDCAPTION("Shipping Advice"),FORMAT("Shipping Advice"),TABLECAPTION);
                IF WhseShpmntConflict("Document Type","No.","Shipping Advice") THEN
                  ERROR(STRSUBSTNO(Text070,FIELDCAPTION("Shipping Advice"),FORMAT("Shipping Advice"),TABLECAPTION));
                WhseSourceHeader.SalesHeaderVerifyChange(Rec,xRec);
            end;
        }
        field(5751;"Shipped Not Invoiced";Boolean)
        {
            AccessByPermission = TableData 110=R;
            CalcFormula = Exist("Sales Line" WHERE (Document Type=FIELD(Document Type),
                                                    Document No.=FIELD(No.),
                                                    Qty. Shipped Not Invoiced=FILTER(<>0)));
            Caption = 'Shipped Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752;"Completely Shipped";Boolean)
        {
            CalcFormula = Min("Sales Line"."Completely Shipped" WHERE (Document Type=FIELD(Document Type),
                                                                       Document No.=FIELD(No.),
                                                                       Type=FILTER(<>' '),
                                                                       Location Code=FIELD(Location Filter)));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753;"Posting from Whse. Ref.";Integer)
        {
            AccessByPermission = TableData 14=R;
            Caption = 'Posting from Whse. Ref.';
        }
        field(5754;"Location Filter";Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5755;Shipped;Boolean)
        {
            AccessByPermission = TableData 110=R;
            CalcFormula = Exist("Sales Line" WHERE (Document Type=FIELD(Document Type),
                                                    Document No.=FIELD(No.),
                                                    Qty. Shipped (Base)=FILTER(<>0)));
            Caption = 'Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5790;"Requested Delivery Date";Date)
        {
            AccessByPermission = TableData 99000880=R;
            Caption = 'Requested Delivery Date';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF "Promised Delivery Date" <> 0D THEN
                  ERROR(
                    Text028,
                    FIELDCAPTION("Requested Delivery Date"),
                    FIELDCAPTION("Promised Delivery Date"));

                IF "Requested Delivery Date" <> xRec."Requested Delivery Date" THEN
                  UpdateSalesLines(FIELDCAPTION("Requested Delivery Date"),CurrFieldNo <> 0);
            end;
        }
        field(5791;"Promised Delivery Date";Date)
        {
            AccessByPermission = TableData 99000880=R;
            Caption = 'Promised Delivery Date';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF "Promised Delivery Date" <> xRec."Promised Delivery Date" THEN
                  UpdateSalesLines(FIELDCAPTION("Promised Delivery Date"),CurrFieldNo <> 0);
            end;
        }
        field(5792;"Shipping Time";DateFormula)
        {
            AccessByPermission = TableData 110=R;
            Caption = 'Shipping Time';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF "Shipping Time" <> xRec."Shipping Time" THEN
                  UpdateSalesLines(FIELDCAPTION("Shipping Time"),CurrFieldNo <> 0);
            end;
        }
        field(5793;"Outbound Whse. Handling Time";DateFormula)
        {
            AccessByPermission = TableData 7320=R;
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                IF ("Outbound Whse. Handling Time" <> xRec."Outbound Whse. Handling Time") AND
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                THEN
                  UpdateSalesLines(FIELDCAPTION("Outbound Whse. Handling Time"),CurrFieldNo <> 0);
            end;
        }
        field(5794;"Shipping Agent Service Code";Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE (Shipping Agent Code=FIELD(Shipping Agent Code));

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                GetShippingTime(FIELDNO("Shipping Agent Service Code"));
                UpdateSalesLines(FIELDCAPTION("Shipping Agent Service Code"),CurrFieldNo <> 0);
            end;
        }
        field(5795;"Late Order Shipping";Boolean)
        {
            AccessByPermission = TableData 110=R;
            CalcFormula = Exist("Sales Line" WHERE (Document Type=FIELD(Document Type),
                                                    Sell-to Customer No.=FIELD(Sell-to Customer No.),
                                                    Document No.=FIELD(No.),
                                                    Shipment Date=FIELD(Date Filter),
                                                    Outstanding Quantity=FILTER(<>0)));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5796;"Date Filter";Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800;Receive;Boolean)
        {
            Caption = 'Receive';
        }
        field(5801;"Return Receipt No.";Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        field(5802;"Return Receipt No. Series";Code[20])
        {
            Caption = 'Return Receipt No. Series';
            TableRelation = "No. Series";

            trigger OnLookup();
            begin
                WITH SalesHeader DO BEGIN
                  SalesHeader := Rec;
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Return Receipt Nos.");
                  IF NoSeriesMgt.LookupSeries(SalesSetup."Posted Return Receipt Nos.","Return Receipt No. Series") THEN
                    VALIDATE("Return Receipt No. Series");
                  Rec := SalesHeader;
                END;
            end;

            trigger OnValidate();
            begin
                IF "Return Receipt No. Series" <> '' THEN BEGIN
                  SalesSetup.GET;
                  SalesSetup.TESTFIELD("Posted Return Receipt Nos.");
                  NoSeriesMgt.TestSeries(SalesSetup."Posted Return Receipt Nos.","Return Receipt No. Series");
                END;
                TESTFIELD("Return Receipt No.",'');
            end;
        }
        field(5803;"Last Return Receipt No.";Code[20])
        {
            Caption = 'Last Return Receipt No.';
            Editable = false;
            TableRelation = "Return Receipt Header";
        }
        field(7001;"Allow Line Disc.";Boolean)
        {
            Caption = 'Allow Line Disc.';

            trigger OnValidate();
            begin
                TESTFIELD(Status,Status::Open);
                MessageIfSalesLinesExist(FIELDCAPTION("Allow Line Disc."));
            end;
        }
        field(7200;"Get Shipment Used";Boolean)
        {
            Caption = 'Get Shipment Used';
            Editable = false;
        }
        field(8000;Id;Guid)
        {
            Caption = 'Id';
        }
        field(9000;"Assigned User ID";Code[50])
        {
            Caption = 'Assigned User ID';
            TableRelation = "User Setup";

            trigger OnValidate();
            begin
                IF NOT UserSetupMgt.CheckRespCenter2(0,"Responsibility Center","Assigned User ID") THEN
                  ERROR(
                    Text061,"Assigned User ID",
                    RespCenter.TABLECAPTION,UserSetupMgt.GetSalesFilter2("Assigned User ID"));
            end;
        }
    }

    keys
    {
        key(Key1;"Document Type","No.")
        {
        }
        key(Key2;"No.","Document Type")
        {
        }
        key(Key3;"Document Type","Sell-to Customer No.")
        {
        }
        key(Key4;"Document Type","Bill-to Customer No.")
        {
        }
        key(Key5;"Document Type","Combine Shipments","Bill-to Customer No.","Currency Code","EU 3-Party Trade","Dimension Set ID")
        {
        }
        key(Key6;"Sell-to Customer No.","External Document No.")
        {
        }
        key(Key7;"Document Type","Sell-to Contact No.")
        {
        }
        key(Key8;"Bill-to Contact No.")
        {
        }
        key(Key9;"Incoming Document Entry No.")
        {
        }
        key(Key10;"Document Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick;"No.","Sell-to Customer Name",Amount,"Sell-to Contact","Amount Including VAT")
        {
        }
    }

    trigger OnDelete();
    var
        CustInvoiceDisc : Record "19";
        PostSalesDelete : Codeunit "363";
        ArchiveManagement : Codeunit "5063";
    begin
        IF NOT UserSetupMgt.CheckRespCenter(0,"Responsibility Center") THEN
          ERROR(
            Text022,
            RespCenter.TABLECAPTION,UserSetupMgt.GetSalesFilter);

        ArchiveManagement.AutoArchiveSalesDocument(Rec);
        PostSalesDelete.DeleteHeader(
          Rec,SalesShptHeader,SalesInvHeader,SalesCrMemoHeader,ReturnRcptHeader,
          SalesInvHeaderPrepmt,SalesCrMemoHeaderPrepmt);
        UpdateOpportunity;

        VALIDATE("Applies-to ID",'');
        VALIDATE("Incoming Document Entry No.",0);

        ApprovalsMgmt.OnDeleteRecordInApprovalRequest(RECORDID);
        SalesLine.RESET;
        SalesLine.LOCKTABLE;

        WhseRequest.SETRANGE("Source Type",DATABASE::"Sales Line");
        WhseRequest.SETRANGE("Source Subtype","Document Type");
        WhseRequest.SETRANGE("Source No.","No.");
        IF NOT WhseRequest.ISEMPTY THEN
          WhseRequest.DELETEALL(TRUE);

        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETRANGE(Type,SalesLine.Type::"Charge (Item)");

        DeleteSalesLines;
        SalesLine.SETRANGE(Type);
        DeleteSalesLines;

        SalesCommentLine.SETRANGE("Document Type","Document Type");
        SalesCommentLine.SETRANGE("No.","No.");
        SalesCommentLine.DELETEALL;

        IF (SalesShptHeader."No." <> '') OR
           (SalesInvHeader."No." <> '') OR
           (SalesCrMemoHeader."No." <> '') OR
           (ReturnRcptHeader."No." <> '') OR
           (SalesInvHeaderPrepmt."No." <> '') OR
           (SalesCrMemoHeaderPrepmt."No." <> '')
        THEN
          MESSAGE(PostedDocsToPrintCreatedMsg);

        IF IdentityManagement.IsInvAppId AND CustInvoiceDisc.GET(SalesHeader."Invoice Disc. Code") THEN
          CustInvoiceDisc.DELETE; // Cleanup of autogenerated cust. invoice discounts
    end;

    trigger OnInsert();
    begin
        InitInsert;
        InsertMode := TRUE;

        SetSellToCustomerFromFilter;

        IF GetFilterContNo <> '' THEN
          VALIDATE("Sell-to Contact No.",GetFilterContNo);

        IF "Salesperson Code" = '' THEN
          SetDefaultSalesperson;
    end;

    trigger OnRename();
    begin
        ERROR(Text003,TABLECAPTION);
    end;

    var
        Text003 : Label 'You cannot rename a %1.';
        ConfirmChangeQst : TextConst Comment='%1 = a Field Caption like Currency Code',ENU='Do you want to change %1?';
        Text005 : Label 'You cannot reset %1 because the document still has one or more lines.';
        Text006 : Label 'You cannot change %1 because the order is associated with one or more purchase orders.';
        Text007 : Label '%1 cannot be greater than %2 in the %3 table.';
        Text009 : Label 'Deleting this document will cause a gap in the number series for shipments. An empty shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text012 : Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text014 : Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text015 : Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.\\Do you want to change %1?';
        Text017 : Label 'You must delete the existing sales lines before you can change %1.';
        Text018 : Label 'You have changed %1 on the sales header, but it has not been changed on the existing sales lines.\';
        Text019 : Label 'You must update the existing sales lines manually.';
        Text020 : Label 'The change may affect the exchange rate used in the price calculation of the sales lines.';
        Text021 : Label 'Do you want to update the exchange rate?';
        Text022 : Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.';
        Text024 : Label 'You have modified the %1 field. The recalculation of VAT may cause penny differences, so you must check the amounts afterward. Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text027 : Label 'Your identification is set up to process from %1 %2 only.';
        Text028 : Label 'You cannot change the %1 when the %2 has been filled in.';
        Text030 : Label 'Deleting this document will cause a gap in the number series for return receipts. An empty return receipt %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text031 : Label 'You have modified %1.\\';
        Text032 : Label 'Do you want to update the lines?';
        SalesSetup : Record "311";
        GLSetup : Record "98";
        GLAcc : Record "15";
        SalesHeader : Record "36";
        SalesLine : Record "37";
        CustLedgEntry : Record "21";
        Cust : Record "18";
        PaymentTerms : Record "3";
        PaymentMethod : Record "289";
        CurrExchRate : Record "330";
        SalesCommentLine : Record "44";
        PostCode : Record "225";
        BankAcc : Record "270";
        SalesShptHeader : Record "110";
        SalesInvHeader : Record "112";
        SalesCrMemoHeader : Record "114";
        ReturnRcptHeader : Record "6660";
        SalesInvHeaderPrepmt : Record "112";
        SalesCrMemoHeaderPrepmt : Record "114";
        GenBusPostingGrp : Record "250";
        RespCenter : Record "5714";
        InvtSetup : Record "313";
        Location : Record "14";
        WhseRequest : Record "5765";
        ReservEntry : Record "337";
        TempReservEntry : Record "337" temporary;
        CompanyInfo : Record "79";
        UserSetupMgt : Codeunit "5700";
        NoSeriesMgt : Codeunit "396";
        CustCheckCreditLimit : Codeunit "312";
        DimMgt : Codeunit "408";
        IdentityManagement : Codeunit "9801";
        ApprovalsMgmt : Codeunit "1535";
        WhseSourceHeader : Codeunit "5781";
        SalesLineReserve : Codeunit "99000832";
        PostingSetupMgt : Codeunit "48";
        CurrencyDate : Date;
        HideValidationDialog : Boolean;
        Confirmed : Boolean;
        Text035 : Label 'You cannot Release Quote or Make Order unless you specify a customer on the quote.\\Do you want to create customer(s) now?';
        Text037 : Label 'Contact %1 %2 is not related to customer %3.';
        Text038 : Label 'Contact %1 %2 is related to a different company than customer %3.';
        Text039 : Label 'Contact %1 %2 is not related to a customer.';
        Text040 : Label 'A won opportunity is linked to this order.\It has to be changed to status Lost before the Order can be deleted.\Do you want to change the status for this opportunity now?';
        Text044 : Label 'The status of the opportunity has not been changed. The program has aborted deleting the order.';
        SkipSellToContact : Boolean;
        SkipBillToContact : Boolean;
        Text045 : TextConst ENU='You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.';
        Text048 : Label 'Sales quote %1 has already been assigned to opportunity %2. Would you like to reassign this quote?';
        Text049 : Label 'The %1 field cannot be blank because this quote is linked to an opportunity.';
        InsertMode : Boolean;
        HideCreditCheckDialogue : Boolean;
        Text051 : Label 'The sales %1 %2 already exists.';
        Text053 : Label 'You must cancel the approval process if you wish to change the %1.';
        Text056 : Label 'Deleting this document will cause a gap in the number series for prepayment invoices. An empty prepayment invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text057 : Label 'Deleting this document will cause a gap in the number series for prepayment credit memos. An empty prepayment credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text061 : Label '%1 is set up to process from %2 %3 only.';
        Text062 : Label 'You cannot change %1 because the corresponding %2 %3 has been assigned to this %4.';
        Text063 : Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.\\Do you want to continue?';
        Text064 : Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateDocumentDate : Boolean;
        Text066 : Label 'You cannot change %1 to %2 because an open inventory pick on the %3.';
        Text070 : Label 'You cannot change %1  to %2 because an open warehouse shipment exists for the %3.';
        BilltoCustomerNoChanged : Boolean;
        SelectNoSeriesAllowed : Boolean;
        PrepaymentInvoicesNotPaidErr : Label 'You cannot post the document of type %1 with the number %2 before all related prepayment invoices are fully posted and paid.', Comment='You cannot post the document of type Order with the number 1001 before all related prepayment invoices are fully posted and paid.';
        Text072 : Label 'There are unpaid prepayment invoices related to the document of type %1 with the number %2.';
        DeferralLineQst : Label 'Do you want to update the deferral schedules for the lines?';
        SynchronizingMsg : Label 'Synchronizing ...\ from: Sales Header with %1\ to: Assembly Header with %2.';
        EstimateTxt : Label 'Estimate';
        ShippingAdviceErr : Label 'This order must be a complete shipment.';
        PostedDocsToPrintCreatedMsg : Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        DocumentNotPostedClosePageQst : Label 'The document has not been posted.\Are you sure you want to exit?';
        SelectCustomerTemplateQst : Label 'Do you want to select the customer template?';
        ModifyCustomerAddressNotificationLbl : Label 'Update the address';
        DontShowAgainActionLbl : Label 'Don''t show again';
        DontShowAgainFunctionTok : Label 'HideNotificationForCurrentUser';
        UpdateAddressWithSellToAddressFunctionTok : Label 'CopySellToCustomerAddressFieldsFromSalesDocument';
        UpdateAddressWithBilltoAddressTok : Label 'CopyBillToCustomerAddressFieldsFromSalesDocument';
        ModifyCustomerAddressNotificationMsg : TextConst Comment='%1=customer name',ENU='The address you entered for %1 is different from the customer''s existing address.';
        ValidVATNoMsg : Label 'The VAT registration number is valid.';
        InvalidVatRegNoMsg : Label 'The VAT registration number is not valid. Try entering the number again.';
        SellToCustomerTxt : Label 'Sell-to Customer';
        BillToCustomerTxt : Label 'Bill-to Customer';
        ModifySellToCustomerAddressNotificationNameTxt : Label 'Update Sell-to Customer Address';
        ModifySellToCustomerAddressNotificationDescriptionTxt : Label 'Warn if the sell-to address on sales documents is different from the customer''s existing address.';
        ModifyBillToCustomerAddressNotificationNameTxt : Label 'Update Bill-to Customer Address';
        ModifyBillToCustomerAddressNotificationDescriptionTxt : Label 'Warn if the bill-to address on sales documents is different from the customer''s existing address.';

    [Scope('Personalization')]
    procedure InitInsert();
    begin
        IF "No." = '' THEN BEGIN
          TestNoSeries;
          NoSeriesMgt.InitSeries(GetNoSeriesCode,xRec."No. Series","Posting Date","No.","No. Series");
        END;

        InitRecord;
    end;

    [Scope('Personalization')]
    procedure InitRecord();
    var
        ArchiveManagement : Codeunit "5063";
    begin
        SalesSetup.GET;

        CASE "Document Type" OF
          "Document Type"::Quote,"Document Type"::Order:
            BEGIN
              NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Invoice Nos.");
              NoSeriesMgt.SetDefaultSeries("Shipping No. Series",SalesSetup."Posted Shipment Nos.");
              IF "Document Type" = "Document Type"::Order THEN BEGIN
                NoSeriesMgt.SetDefaultSeries("Prepayment No. Series",SalesSetup."Posted Prepmt. Inv. Nos.");
                NoSeriesMgt.SetDefaultSeries("Prepmt. Cr. Memo No. Series",SalesSetup."Posted Prepmt. Cr. Memo Nos.");
              END;
            END;
          "Document Type"::Invoice:
            BEGIN
              IF ("No. Series" <> '') AND
                 (SalesSetup."Invoice Nos." = SalesSetup."Posted Invoice Nos.")
              THEN
                "Posting No. Series" := "No. Series"
              ELSE
                NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Invoice Nos.");
              IF SalesSetup."Shipment on Invoice" THEN
                NoSeriesMgt.SetDefaultSeries("Shipping No. Series",SalesSetup."Posted Shipment Nos.");
            END;
          "Document Type"::"Return Order":
            BEGIN
              NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Credit Memo Nos.");
              NoSeriesMgt.SetDefaultSeries("Return Receipt No. Series",SalesSetup."Posted Return Receipt Nos.");
            END;
          "Document Type"::"Credit Memo":
            BEGIN
              IF ("No. Series" <> '') AND
                 (SalesSetup."Credit Memo Nos." = SalesSetup."Posted Credit Memo Nos.")
              THEN
                "Posting No. Series" := "No. Series"
              ELSE
                NoSeriesMgt.SetDefaultSeries("Posting No. Series",SalesSetup."Posted Credit Memo Nos.");
              IF SalesSetup."Return Receipt on Credit Memo" THEN
                NoSeriesMgt.SetDefaultSeries("Return Receipt No. Series",SalesSetup."Posted Return Receipt Nos.");
            END;
        END;

        IF "Document Type" IN ["Document Type"::Order,"Document Type"::Invoice,"Document Type"::Quote] THEN
          BEGIN
          "Shipment Date" := WORKDATE;
          "Order Date" := WORKDATE;
        END;
        IF "Document Type" = "Document Type"::"Return Order" THEN
          "Order Date" := WORKDATE;

        IF NOT ("Document Type" IN ["Document Type"::"Blanket Order","Document Type"::Quote]) AND
           ("Posting Date" = 0D)
        THEN
          "Posting Date" := WORKDATE;

        IF SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" THEN
          "Posting Date" := 0D;

        "Document Date" := WORKDATE;

        VALIDATE("Location Code",UserSetupMgt.GetLocation(0,Cust."Location Code","Responsibility Center"));

        IF IsCreditDocType THEN BEGIN
          GLSetup.GET;
          Correction := GLSetup."Mark Cr. Memos as Corrections";
        END;

        "Posting Description" := FORMAT("Document Type") + ' ' + "No.";

        UpdateOutboundWhseHandlingTime;

        "Responsibility Center" := UserSetupMgt.GetRespCenter(0,"Responsibility Center");
        "Doc. No. Occurrence" := ArchiveManagement.GetNextOccurrenceNo(DATABASE::"Sales Header","Document Type","No.");

        OnAfterInitRecord(Rec);
    end;

    local procedure InitNoSeries();
    begin
        IF xRec."Shipping No." <> '' THEN BEGIN
          "Shipping No. Series" := xRec."Shipping No. Series";
          "Shipping No." := xRec."Shipping No.";
        END;
        IF xRec."Posting No." <> '' THEN BEGIN
          "Posting No. Series" := xRec."Posting No. Series";
          "Posting No." := xRec."Posting No.";
        END;
        IF xRec."Return Receipt No." <> '' THEN BEGIN
          "Return Receipt No. Series" := xRec."Return Receipt No. Series";
          "Return Receipt No." := xRec."Return Receipt No.";
        END;
        IF xRec."Prepayment No." <> '' THEN BEGIN
          "Prepayment No. Series" := xRec."Prepayment No. Series";
          "Prepayment No." := xRec."Prepayment No.";
        END;
        IF xRec."Prepmt. Cr. Memo No." <> '' THEN BEGIN
          "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
          "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
        END;

        OnAfterInitNoSeries(Rec);
    end;

    procedure AssistEdit(OldSalesHeader : Record "36") : Boolean;
    var
        SalesHeader2 : Record "36";
    begin
        WITH SalesHeader DO BEGIN
          COPY(Rec);
          SalesSetup.GET;
          TestNoSeries;
          IF NoSeriesMgt.SelectSeries(GetNoSeriesCode,OldSalesHeader."No. Series","No. Series") THEN BEGIN
            IF ("Sell-to Customer No." = '') AND ("Sell-to Contact No." = '') THEN BEGIN
              HideCreditCheckDialogue := FALSE;
              CheckCreditMaxBeforeInsert;
              HideCreditCheckDialogue := TRUE;
            END;
            NoSeriesMgt.SetSeries("No.");
            IF SalesHeader2.GET("Document Type","No.") THEN
              ERROR(Text051,LOWERCASE(FORMAT("Document Type")),"No.");
            Rec := SalesHeader;
            EXIT(TRUE);
          END;
        END;
    end;

    local procedure TestNoSeries();
    begin
        SalesSetup.GET;

        CASE "Document Type" OF
          "Document Type"::Quote:
            SalesSetup.TESTFIELD("Quote Nos.");
          "Document Type"::Order:
            SalesSetup.TESTFIELD("Order Nos.");
          "Document Type"::Invoice:
            BEGIN
              SalesSetup.TESTFIELD("Invoice Nos.");
              SalesSetup.TESTFIELD("Posted Invoice Nos.");
            END;
          "Document Type"::"Return Order":
            SalesSetup.TESTFIELD("Return Order Nos.");
          "Document Type"::"Credit Memo":
            BEGIN
              SalesSetup.TESTFIELD("Credit Memo Nos.");
              SalesSetup.TESTFIELD("Posted Credit Memo Nos.");
            END;
          "Document Type"::"Blanket Order":
            SalesSetup.TESTFIELD("Blanket Order Nos.");
        END;

        OnAfterTestNoSeries(Rec);
    end;

    local procedure GetNoSeriesCode() : Code[20];
    var
        NoSeriesCode : Code[20];
    begin
        CASE "Document Type" OF
          "Document Type"::Quote:
            NoSeriesCode := SalesSetup."Quote Nos.";
          "Document Type"::Order:
            NoSeriesCode := SalesSetup."Order Nos.";
          "Document Type"::Invoice:
            NoSeriesCode := SalesSetup."Invoice Nos.";
          "Document Type"::"Return Order":
            NoSeriesCode := SalesSetup."Return Order Nos.";
          "Document Type"::"Credit Memo":
            NoSeriesCode := SalesSetup."Credit Memo Nos.";
          "Document Type"::"Blanket Order":
            NoSeriesCode := SalesSetup."Blanket Order Nos.";
        END;
        EXIT(NoSeriesMgt.GetNoSeriesWithCheck(NoSeriesCode,SelectNoSeriesAllowed,"No. Series"));
    end;

    local procedure GetPostingNoSeriesCode() : Code[10];
    begin
        IF IsCreditDocType THEN
          EXIT(SalesSetup."Posted Credit Memo Nos.");
        EXIT(SalesSetup."Posted Invoice Nos.");
    end;

    local procedure GetPostingPrepaymentNoSeriesCode() : Code[10];
    begin
        IF IsCreditDocType THEN
          EXIT(SalesSetup."Posted Prepmt. Cr. Memo Nos.");
        EXIT(SalesSetup."Posted Prepmt. Inv. Nos.");
    end;

    local procedure TestNoSeriesDate(No : Code[20];NoSeriesCode : Code[20];NoCapt : Text[1024];NoSeriesCapt : Text[1024]);
    var
        NoSeries : Record "308";
    begin
        IF (No <> '') AND (NoSeriesCode <> '') THEN BEGIN
          NoSeries.GET(NoSeriesCode);
          IF NoSeries."Date Order" THEN
            ERROR(
              Text045,
              FIELDCAPTION("Posting Date"),NoSeriesCapt,NoSeriesCode,
              NoSeries.FIELDCAPTION("Date Order"),NoSeries."Date Order","Document Type",
              NoCapt,No);
        END;
    end;

    [Scope('Personalization')]
    procedure ConfirmDeletion() : Boolean;
    var
        SourceCode : Record "230";
        SourceCodeSetup : Record "242";
        PostSalesDelete : Codeunit "363";
    begin
        SourceCodeSetup.GET;
        SourceCodeSetup.TESTFIELD("Deleted Document");
        SourceCode.GET(SourceCodeSetup."Deleted Document");

        PostSalesDelete.InitDeleteHeader(
          Rec,SalesShptHeader,SalesInvHeader,SalesCrMemoHeader,ReturnRcptHeader,
          SalesInvHeaderPrepmt,SalesCrMemoHeaderPrepmt,SourceCode.Code);

        IF SalesShptHeader."No." <> '' THEN
          IF NOT CONFIRM(Text009,TRUE,SalesShptHeader."No.") THEN
            EXIT;
        IF SalesInvHeader."No." <> '' THEN
          IF NOT CONFIRM(Text012,TRUE,SalesInvHeader."No.") THEN
            EXIT;
        IF SalesCrMemoHeader."No." <> '' THEN
          IF NOT CONFIRM(Text014,TRUE,SalesCrMemoHeader."No.") THEN
            EXIT;
        IF ReturnRcptHeader."No." <> '' THEN
          IF NOT CONFIRM(Text030,TRUE,ReturnRcptHeader."No.") THEN
            EXIT;
        IF "Prepayment No." <> '' THEN
          IF NOT CONFIRM(Text056,TRUE,SalesInvHeaderPrepmt."No.") THEN
            EXIT;
        IF "Prepmt. Cr. Memo No." <> '' THEN
          IF NOT CONFIRM(Text057,TRUE,SalesCrMemoHeaderPrepmt."No.") THEN
            EXIT;
        EXIT(TRUE);
    end;

    local procedure GetCust(CustNo : Code[20]);
    begin
        IF NOT (("Document Type" = "Document Type"::Quote) AND (CustNo = '')) THEN BEGIN
          IF CustNo <> Cust."No." THEN
            Cust.GET(CustNo);
        END ELSE
          CLEAR(Cust);
    end;

    [Scope('Personalization')]
    procedure SalesLinesExist() : Boolean;
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        EXIT(SalesLine.FINDFIRST);
    end;

    local procedure RecreateSalesLines(ChangedFieldName : Text[100]);
    var
        TempSalesLine : Record "37" temporary;
        ItemChargeAssgntSales : Record "5809";
        TempItemChargeAssgntSales : Record "5809" temporary;
        TempInteger : Record "2000000026" temporary;
        TempATOLink : Record "904" temporary;
        ATOLink : Record "904";
        TransferExtendedText : Codeunit "378";
        ExtendedTextAdded : Boolean;
    begin
        IF SalesLinesExist THEN BEGIN
          IF GetHideValidationDialog OR NOT GUIALLOWED THEN
            Confirmed := TRUE
          ELSE
            Confirmed :=
              CONFIRM(
                Text015,FALSE,ChangedFieldName);
          IF Confirmed THEN BEGIN
            SalesLine.LOCKTABLE;
            ItemChargeAssgntSales.LOCKTABLE;
            ReservEntry.LOCKTABLE;
            MODIFY;
            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type","Document Type");
            SalesLine.SETRANGE("Document No.","No.");
            IF SalesLine.FINDSET THEN BEGIN
              TempReservEntry.DELETEALL;
              RecreateReservEntryReqLine(TempSalesLine,TempATOLink,ATOLink);
              ItemChargeAssgntSales.SETRANGE("Document Type","Document Type");
              ItemChargeAssgntSales.SETRANGE("Document No.","No.");
              TransferItemChargeAssgntSalesToTemp(ItemChargeAssgntSales,TempItemChargeAssgntSales);
              SalesLine.DELETEALL(TRUE);
              SalesLine.INIT;
              SalesLine."Line No." := 0;
              TempSalesLine.FINDSET;
              ExtendedTextAdded := FALSE;
              SalesLine.BlockDynamicTracking(TRUE);
              REPEAT
                IF TempSalesLine."Attached to Line No." = 0 THEN BEGIN
                  CreateSalesLine(TempSalesLine);
                  ExtendedTextAdded := FALSE;

                  IF SalesLine.Type = SalesLine.Type::Item THEN BEGIN
                    ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type",TempSalesLine."Document Type");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.",TempSalesLine."Document No.");
                    TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.",TempSalesLine."Line No.");
                    IF TempItemChargeAssgntSales.FINDSET THEN
                      REPEAT
                        IF NOT TempItemChargeAssgntSales.MARK THEN BEGIN
                          TempItemChargeAssgntSales."Applies-to Doc. Line No." := SalesLine."Line No.";
                          TempItemChargeAssgntSales.Description := SalesLine.Description;
                          TempItemChargeAssgntSales.MODIFY;
                          TempItemChargeAssgntSales.MARK(TRUE);
                        END;
                      UNTIL TempItemChargeAssgntSales.NEXT = 0;
                  END;
                  IF SalesLine.Type = SalesLine.Type::"Charge (Item)" THEN BEGIN
                    TempInteger.INIT;
                    TempInteger.Number := SalesLine."Line No.";
                    TempInteger.INSERT;
                  END;
                END ELSE
                  IF NOT ExtendedTextAdded THEN BEGIN
                    TransferExtendedText.SalesCheckIfAnyExtText(SalesLine,TRUE);
                    TransferExtendedText.InsertSalesExtText(SalesLine);
                    OnAfterTransferExtendedTextForSalesLineRecreation(SalesLine);

                    SalesLine.FINDLAST;
                    ExtendedTextAdded := TRUE;
                  END;
                CopyReservEntryFromTemp(TempSalesLine,SalesLine."Line No.");
                RecreateReqLine(TempSalesLine,SalesLine."Line No.",FALSE);
                SynchronizeForReservations(SalesLine,TempSalesLine);

                IF TempATOLink.AsmExistsForSalesLine(TempSalesLine) THEN BEGIN
                  ATOLink := TempATOLink;
                  ATOLink."Document Line No." := SalesLine."Line No.";
                  ATOLink.INSERT;
                  ATOLink.UpdateAsmFromSalesLineATOExist(SalesLine);
                  TempATOLink.DELETE;
                END;
              UNTIL TempSalesLine.NEXT = 0;

              ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
              TempSalesLine.SETRANGE(Type,SalesLine.Type::"Charge (Item)");
              CreateItemChargeAssgntSales(ItemChargeAssgntSales,TempItemChargeAssgntSales,TempSalesLine,TempInteger);
              TempSalesLine.SETRANGE(Type);
              TempSalesLine.DELETEALL;
              ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
              TempItemChargeAssgntSales.DELETEALL;
            END;
          END ELSE
            ERROR(
              Text017,ChangedFieldName);
        END;
        SalesLine.BlockDynamicTracking(FALSE);
    end;

    local procedure MessageIfSalesLinesExist(ChangedFieldName : Text[100]);
    begin
        IF SalesLinesExist AND NOT GetHideValidationDialog THEN
          MESSAGE(
            Text018 +
            Text019,
            ChangedFieldName);
    end;

    local procedure PriceMessageIfSalesLinesExist(ChangedFieldName : Text[100]);
    begin
        IF SalesLinesExist AND NOT GetHideValidationDialog THEN
          MESSAGE(
            Text018 +
            Text020,ChangedFieldName);
    end;

    local procedure UpdateCurrencyFactor();
    begin
        IF "Currency Code" <> '' THEN BEGIN
          IF "Posting Date" <> 0D THEN
            CurrencyDate := "Posting Date"
          ELSE
            CurrencyDate := WORKDATE;

          "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate,"Currency Code");
        END ELSE
          "Currency Factor" := 0;
    end;

    local procedure ConfirmUpdateCurrencyFactor();
    begin
        IF GetHideValidationDialog THEN
          Confirmed := TRUE
        ELSE
          Confirmed := CONFIRM(Text021,FALSE);
        IF Confirmed THEN
          VALIDATE("Currency Factor")
        ELSE
          "Currency Factor" := xRec."Currency Factor";
    end;

    [Scope('Personalization')]
    procedure SetHideValidationDialog(NewHideValidationDialog : Boolean);
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetHideValidationDialog() : Boolean;
    var
        IdentityManagement : Codeunit "9801";
    begin
        EXIT(HideValidationDialog OR IdentityManagement.IsInvAppId);
    end;

    [Scope('Personalization')]
    procedure UpdateSalesLines(ChangedFieldName : Text[100];AskQuestion : Boolean);
    var
        JobTransferLine : Codeunit "1004";
        PermissionManager : Codeunit "9002";
        Question : Text[250];
        NotRunningOnSaaS : Boolean;
    begin
        IF NOT SalesLinesExist THEN
          EXIT;

        NotRunningOnSaaS := TRUE;
        CASE ChangedFieldName OF
          FIELDCAPTION("Shipping Agent Code"),
          FIELDCAPTION("Shipping Agent Service Code"):
            NotRunningOnSaaS := NOT PermissionManager.SoftwareAsAService;
        END;
        IF AskQuestion THEN BEGIN
          Question := STRSUBSTNO(
              Text031 +
              Text032,ChangedFieldName);
          IF GUIALLOWED THEN
            IF NotRunningOnSaaS THEN
              IF DIALOG.CONFIRM(Question,TRUE) THEN
                CASE ChangedFieldName OF
                  FIELDCAPTION("Shipment Date"),
                  FIELDCAPTION("Shipping Agent Code"),
                  FIELDCAPTION("Shipping Agent Service Code"),
                  FIELDCAPTION("Shipping Time"),
                  FIELDCAPTION("Requested Delivery Date"),
                  FIELDCAPTION("Promised Delivery Date"),
                  FIELDCAPTION("Outbound Whse. Handling Time"):
                    ConfirmResvDateConflict;
                END
              ELSE
                EXIT
            ELSE
              ConfirmResvDateConflict;
        END;

        SalesLine.LOCKTABLE;
        MODIFY;

        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        IF SalesLine.FINDSET THEN
          REPEAT
            CASE ChangedFieldName OF
              FIELDCAPTION("Shipment Date"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Shipment Date","Shipment Date");
              FIELDCAPTION("Currency Factor"):
                IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
                  SalesLine.VALIDATE("Unit Price");
                  SalesLine.VALIDATE("Unit Cost (LCY)");
                  IF SalesLine."Job No." <> '' THEN
                    JobTransferLine.FromSalesHeaderToPlanningLine(SalesLine,"Currency Factor");
                END;
              FIELDCAPTION("Transaction Type"):
                SalesLine.VALIDATE("Transaction Type","Transaction Type");
              FIELDCAPTION("Transport Method"):
                SalesLine.VALIDATE("Transport Method","Transport Method");
              FIELDCAPTION("Exit Point"):
                SalesLine.VALIDATE("Exit Point","Exit Point");
              FIELDCAPTION(Area):
                SalesLine.VALIDATE(Area,Area);
              FIELDCAPTION("Transaction Specification"):
                SalesLine.VALIDATE("Transaction Specification","Transaction Specification");
              FIELDCAPTION("Shipping Agent Code"):
                SalesLine.VALIDATE("Shipping Agent Code","Shipping Agent Code");
              FIELDCAPTION("Shipping Agent Service Code"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Shipping Agent Service Code","Shipping Agent Service Code");
              FIELDCAPTION("Shipping Time"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Shipping Time","Shipping Time");
              FIELDCAPTION("Prepayment %"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Prepayment %","Prepayment %");
              FIELDCAPTION("Requested Delivery Date"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Requested Delivery Date","Requested Delivery Date");
              FIELDCAPTION("Promised Delivery Date"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Promised Delivery Date","Promised Delivery Date");
              FIELDCAPTION("Outbound Whse. Handling Time"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Outbound Whse. Handling Time","Outbound Whse. Handling Time");
              SalesLine.FIELDCAPTION("Deferral Code"):
                IF SalesLine."No." <> '' THEN
                  SalesLine.VALIDATE("Deferral Code");
              ELSE
                OnUpdateSalesLineByChangedFieldName(Rec,SalesLine,ChangedFieldName);
            END;
            SalesLineReserve.AssignForPlanning(SalesLine);
            SalesLine.MODIFY(TRUE);
          UNTIL SalesLine.NEXT = 0;
    end;

    local procedure ConfirmResvDateConflict();
    var
        ResvEngMgt : Codeunit "99000831";
    begin
        IF ResvEngMgt.ResvExistsForSalesHeader(Rec) THEN
          IF NOT CONFIRM(Text063,FALSE) THEN
            ERROR('');
    end;

    [Scope('Personalization')]
    procedure CreateDim(Type1 : Integer;No1 : Code[20];Type2 : Integer;No2 : Code[20];Type3 : Integer;No3 : Code[20];Type4 : Integer;No4 : Code[20];Type5 : Integer;No5 : Code[20]);
    var
        SourceCodeSetup : Record "242";
        TableID : array [10] of Integer;
        No : array [10] of Code[20];
        OldDimSetID : Integer;
    begin
        SourceCodeSetup.GET;
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        OnAfterCreateDimTableIDs(Rec,CurrFieldNo,TableID,No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec,CurrFieldNo,TableID,No,SourceCodeSetup.Sales,"Shortcut Dimension 1 Code","Shortcut Dimension 2 Code",0,0);

        IF (OldDimSetID <> "Dimension Set ID") AND SalesLinesExist THEN BEGIN
          MODIFY;
          UpdateAllLineDim("Dimension Set ID",OldDimSetID);
        END;
    end;

    local procedure ValidateShortcutDimCode(FieldNumber : Integer;var ShortcutDimCode : Code[20]);
    var
        OldDimSetID : Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber,ShortcutDimCode,"Dimension Set ID");
        IF "No." <> '' THEN
          MODIFY;

        IF OldDimSetID <> "Dimension Set ID" THEN BEGIN
          MODIFY;
          IF SalesLinesExist THEN
            UpdateAllLineDim("Dimension Set ID",OldDimSetID);
        END;
    end;

    local procedure ShippedSalesLinesExist() : Boolean;
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER("Quantity Shipped",'<>0');
        EXIT(SalesLine.FINDFIRST);
    end;

    local procedure ReturnReceiptExist() : Boolean;
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER("Return Qty. Received",'<>0');
        EXIT(SalesLine.FINDFIRST);
    end;

    local procedure DeleteSalesLines();
    var
        ReservMgt : Codeunit "99000845";
    begin
        IF SalesLine.FINDSET THEN BEGIN
          ReservMgt.DeleteDocumentReservation(DATABASE::"Sales Line","Document Type","No.",GetHideValidationDialog);
          REPEAT
            SalesLine.SuspendStatusCheck(TRUE);
            SalesLine.DELETE(TRUE);
          UNTIL SalesLine.NEXT = 0;
        END;
    end;

    local procedure ClearItemAssgntSalesFilter(var TempItemChargeAssgntSales : Record "5809" temporary);
    begin
        TempItemChargeAssgntSales.SETRANGE("Document Line No.");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SETRANGE("Applies-to Doc. Line No.");
    end;

    [Scope('Personalization')]
    procedure CheckCustomerCreated(Prompt : Boolean) : Boolean;
    var
        Cont : Record "5050";
    begin
        IF ("Bill-to Customer No." <> '') AND ("Sell-to Customer No." <> '') THEN
          EXIT(TRUE);

        IF Prompt THEN
          IF NOT CONFIRM(Text035,TRUE) THEN
            EXIT(FALSE);

        IF "Sell-to Customer No." = '' THEN BEGIN
          TESTFIELD("Sell-to Contact No.");
          TESTFIELD("Sell-to Customer Template Code");
          Cont.GET("Sell-to Contact No.");
          Cont.CreateCustomer("Sell-to Customer Template Code");
          COMMIT;
          GET("Document Type"::Quote,"No.");
        END;

        IF "Bill-to Customer No." = '' THEN BEGIN
          TESTFIELD("Bill-to Contact No.");
          TESTFIELD("Bill-to Customer Template Code");
          Cont.GET("Bill-to Contact No.");
          Cont.CreateCustomer("Bill-to Customer Template Code");
          COMMIT;
          GET("Document Type"::Quote,"No.");
        END;

        EXIT(("Bill-to Customer No." <> '') AND ("Sell-to Customer No." <> ''));
    end;

    local procedure CheckShipmentInfo(var SalesLine : Record "37";BillTo : Boolean);
    begin
        IF "Document Type" = "Document Type"::Order THEN
          SalesLine.SETFILTER("Quantity Shipped",'<>0')
        ELSE
          IF "Document Type" = "Document Type"::Invoice THEN BEGIN
            IF NOT BillTo THEN
              SalesLine.SETRANGE("Sell-to Customer No.",xRec."Sell-to Customer No.");
            SalesLine.SETFILTER("Shipment No.",'<>%1','');
          END;

        IF SalesLine.FINDFIRST THEN
          IF "Document Type" = "Document Type"::Order THEN
            SalesLine.TESTFIELD("Quantity Shipped",0)
          ELSE
            SalesLine.TESTFIELD("Shipment No.",'');
        SalesLine.SETRANGE("Shipment No.");
        SalesLine.SETRANGE("Quantity Shipped");
    end;

    local procedure CheckPrepmtInfo(var SalesLine : Record "37");
    begin
        IF "Document Type" = "Document Type"::Order THEN BEGIN
          SalesLine.SETFILTER("Prepmt. Amt. Inv.",'<>0');
          IF SalesLine.FIND('-') THEN
            SalesLine.TESTFIELD("Prepmt. Amt. Inv.",0);
          SalesLine.SETRANGE("Prepmt. Amt. Inv.");
        END;
    end;

    local procedure CheckReturnInfo(var SalesLine : Record "37";BillTo : Boolean);
    begin
        IF "Document Type" = "Document Type"::"Return Order" THEN
          SalesLine.SETFILTER("Return Qty. Received",'<>0')
        ELSE
          IF "Document Type" = "Document Type"::"Credit Memo" THEN BEGIN
            IF NOT BillTo THEN
              SalesLine.SETRANGE("Sell-to Customer No.",xRec."Sell-to Customer No.");
            SalesLine.SETFILTER("Return Receipt No.",'<>%1','');
          END;

        IF SalesLine.FINDFIRST THEN
          IF "Document Type" = "Document Type"::"Return Order" THEN
            SalesLine.TESTFIELD("Return Qty. Received",0)
          ELSE
            SalesLine.TESTFIELD("Return Receipt No.",'');
    end;

    local procedure CopyReservEntryToTemp(OldSalesLine : Record "37");
    begin
        ReservEntry.RESET;
        ReservEntry.SetSourceFilter(
          DATABASE::"Sales Line",OldSalesLine."Document Type",OldSalesLine."Document No.",OldSalesLine."Line No.",TRUE);
        IF ReservEntry.FINDSET THEN
          REPEAT
            TempReservEntry := ReservEntry;
            TempReservEntry.INSERT;
          UNTIL ReservEntry.NEXT = 0;
        ReservEntry.DELETEALL;
    end;

    local procedure CopyReservEntryFromTemp(OldSalesLine : Record "37";NewSourceRefNo : Integer);
    begin
        TempReservEntry.RESET;
        TempReservEntry.SetSourceFilter(
          DATABASE::"Sales Line",OldSalesLine."Document Type",OldSalesLine."Document No.",OldSalesLine."Line No.",TRUE);
        IF TempReservEntry.FINDSET THEN
          REPEAT
            ReservEntry := TempReservEntry;
            ReservEntry."Source Ref. No." := NewSourceRefNo;
            ReservEntry.INSERT;
          UNTIL TempReservEntry.NEXT = 0;
        TempReservEntry.DELETEALL;
    end;

    local procedure RecreateReqLine(OldSalesLine : Record "37";NewSourceRefNo : Integer;ToTemp : Boolean);
    var
        ReqLine : Record "246";
        TempReqLine : Record "246" temporary;
    begin
        IF ToTemp THEN BEGIN
          ReqLine.SETCURRENTKEY("Order Promising ID","Order Promising Line ID","Order Promising Line No.");
          ReqLine.SETRANGE("Order Promising ID",OldSalesLine."Document No.");
          ReqLine.SETRANGE("Order Promising Line ID",OldSalesLine."Line No.");
          IF ReqLine.FINDSET THEN
            REPEAT
              TempReqLine := ReqLine;
              TempReqLine.INSERT;
            UNTIL ReqLine.NEXT = 0;
          ReqLine.DELETEALL;
        END ELSE BEGIN
          CLEAR(TempReqLine);
          TempReqLine.SETCURRENTKEY("Order Promising ID","Order Promising Line ID","Order Promising Line No.");
          TempReqLine.SETRANGE("Order Promising ID",OldSalesLine."Document No.");
          TempReqLine.SETRANGE("Order Promising Line ID",OldSalesLine."Line No.");
          IF TempReqLine.FINDSET THEN
            REPEAT
              ReqLine := TempReqLine;
              ReqLine."Order Promising Line ID" := NewSourceRefNo;
              ReqLine.INSERT;
            UNTIL TempReqLine.NEXT = 0;
          TempReqLine.DELETEALL;
        END;
    end;

    local procedure UpdateSellToCont(CustomerNo : Code[20]);
    var
        ContBusRel : Record "5054";
        Cust : Record "18";
        OfficeContact : Record "5050";
        OfficeMgt : Codeunit "1630";
    begin
        IF OfficeMgt.GetContact(OfficeContact,CustomerNo) THEN BEGIN
          HideValidationDialog := TRUE;
          UpdateSellToCust(OfficeContact."No.");
          HideValidationDialog := FALSE;
        END ELSE
          IF Cust.GET(CustomerNo) THEN BEGIN
            IF Cust."Primary Contact No." <> '' THEN
              "Sell-to Contact No." := Cust."Primary Contact No."
            ELSE BEGIN
              ContBusRel.RESET;
              ContBusRel.SETCURRENTKEY("Link to Table","No.");
              ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
              ContBusRel.SETRANGE("No.","Sell-to Customer No.");
              IF ContBusRel.FINDFIRST THEN
                "Sell-to Contact No." := ContBusRel."Contact No."
              ELSE
                "Sell-to Contact No." := '';
            END;
            "Sell-to Contact" := Cust.Contact;
          END;
    end;

    local procedure UpdateBillToCont(CustomerNo : Code[20]);
    var
        ContBusRel : Record "5054";
        Cust : Record "18";
    begin
        IF Cust.GET(CustomerNo) THEN BEGIN
          IF Cust."Primary Contact No." <> '' THEN
            "Bill-to Contact No." := Cust."Primary Contact No."
          ELSE BEGIN
            ContBusRel.RESET;
            ContBusRel.SETCURRENTKEY("Link to Table","No.");
            ContBusRel.SETRANGE("Link to Table",ContBusRel."Link to Table"::Customer);
            ContBusRel.SETRANGE("No.","Bill-to Customer No.");
            IF ContBusRel.FINDFIRST THEN
              "Bill-to Contact No." := ContBusRel."Contact No."
            ELSE
              "Bill-to Contact No." := '';
          END;
          "Bill-to Contact" := Cust.Contact;
        END;
    end;

    local procedure UpdateSellToCust(ContactNo : Code[20]);
    var
        ContBusinessRelation : Record "5054";
        Customer : Record "18";
        Cont : Record "5050";
        CustTemplate : Record "5105";
        SearchContact : Record "5050";
        ContactBusinessRelationFound : Boolean;
    begin
        IF NOT Cont.GET(ContactNo) THEN BEGIN
          "Sell-to Contact" := '';
          EXIT;
        END;
        "Sell-to Contact No." := Cont."No.";

        IF Cont.Type = Cont.Type::Person THEN
          ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer,Cont."No.");
        IF NOT ContactBusinessRelationFound THEN
          ContactBusinessRelationFound :=
            ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer,Cont."Company No.");

        IF ContactBusinessRelationFound THEN BEGIN
          IF ("Sell-to Customer No." <> '') AND ("Sell-to Customer No." <> ContBusinessRelation."No.") THEN
            ERROR(Text037,Cont."No.",Cont.Name,"Sell-to Customer No.");

          IF "Sell-to Customer No." = '' THEN BEGIN
            SkipSellToContact := TRUE;
            VALIDATE("Sell-to Customer No.",ContBusinessRelation."No.");
            SkipSellToContact := FALSE;
          END;
        END ELSE BEGIN
          IF "Document Type" = "Document Type"::Quote THEN BEGIN
            IF Cont."Company No." <> '' THEN
              SearchContact.GET(Cont."Company No.")
            ELSE
              SearchContact := Cont;
            "Sell-to Customer Name" := SearchContact."Company Name";
            "Sell-to Customer Name 2" := SearchContact."Name 2";
            SetShipToAddress(
              SearchContact."Company Name",SearchContact."Name 2",SearchContact.Address,SearchContact."Address 2",
              SearchContact.City,SearchContact."Post Code",SearchContact.County,SearchContact."Country/Region Code");
            IF ("Sell-to Customer Template Code" = '') AND (NOT CustTemplate.ISEMPTY) THEN
              VALIDATE("Sell-to Customer Template Code",Cont.FindCustomerTemplate);
          END ELSE
            ERROR(Text039,Cont."No.",Cont.Name);
          "Sell-to Contact" := Cont.Name;
        END;

        IF (Cont.Type = Cont.Type::Company) AND Customer.GET("Sell-to Customer No.") THEN
          "Sell-to Contact" := Customer.Contact
        ELSE
          "Sell-to Contact" := Cont.Name;

        IF "Document Type" = "Document Type"::Quote THEN BEGIN
          IF Customer.GET("Sell-to Customer No.") OR Customer.GET(ContBusinessRelation."No.") THEN BEGIN
            IF Customer."Copy Sell-to Addr. to Qte From" = Customer."Copy Sell-to Addr. to Qte From"::Company THEN BEGIN
              IF Cont."Company No." <> '' THEN
                Cont.GET(Cont."Company No.");
            END;
          END ELSE BEGIN
            IF Cont."Company No." <> '' THEN
              Cont.GET(Cont."Company No.");
          END;
          "Sell-to Address" := Cont.Address;
          "Sell-to Address 2" := Cont."Address 2";
          "Sell-to City" := Cont.City;
          "Sell-to Post Code" := Cont."Post Code";
          "Sell-to County" := Cont.County;
          "Sell-to Country/Region Code" := Cont."Country/Region Code";
        END;
        IF ("Sell-to Customer No." = "Bill-to Customer No.") OR
           ("Bill-to Customer No." = '')
        THEN
          VALIDATE("Bill-to Contact No.","Sell-to Contact No.");
    end;

    local procedure UpdateBillToCust(ContactNo : Code[20]);
    var
        ContBusinessRelation : Record "5054";
        Cust : Record "18";
        Cont : Record "5050";
        CustTemplate : Record "5105";
        SearchContact : Record "5050";
        ContactBusinessRelationFound : Boolean;
    begin
        IF NOT Cont.GET(ContactNo) THEN BEGIN
          "Bill-to Contact" := '';
          EXIT;
        END;
        "Bill-to Contact No." := Cont."No.";

        IF Cust.GET("Bill-to Customer No.") THEN
          "Bill-to Contact" := Cust.Contact
        ELSE
          "Bill-to Contact" := Cont.Name;

        IF Cont.Type = Cont.Type::Person THEN
          ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer,Cont."No.");
        IF NOT ContactBusinessRelationFound THEN
          ContactBusinessRelationFound :=
            ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer,Cont."Company No.");

        IF ContactBusinessRelationFound THEN BEGIN
          IF "Bill-to Customer No." = '' THEN BEGIN
            SkipBillToContact := TRUE;
            VALIDATE("Bill-to Customer No.",ContBusinessRelation."No.");
            SkipBillToContact := FALSE;
            "Bill-to Customer Template Code" := '';
          END ELSE
            IF "Bill-to Customer No." <> ContBusinessRelation."No." THEN
              ERROR(Text037,Cont."No.",Cont.Name,"Bill-to Customer No.");
        END ELSE BEGIN
          IF "Document Type" = "Document Type"::Quote THEN BEGIN
            IF Cont."Company No." <> '' THEN
              SearchContact.GET(Cont."Company No.")
            ELSE
              SearchContact.GET(Cont."No.");

            "Bill-to Name" := SearchContact."Company Name";
            "Bill-to Name 2" := SearchContact."Name 2";
            "Bill-to Address" := SearchContact.Address;
            "Bill-to Address 2" := SearchContact."Address 2";
            "Bill-to City" := SearchContact.City;
            "Bill-to Post Code" := SearchContact."Post Code";
            "Bill-to County" := SearchContact.County;
            "Bill-to Country/Region Code" := SearchContact."Country/Region Code";
            "VAT Registration No." := SearchContact."VAT Registration No.";
            VALIDATE("Currency Code",SearchContact."Currency Code");
            "Language Code" := SearchContact."Language Code";
            IF ("Bill-to Customer Template Code" = '') AND (NOT CustTemplate.ISEMPTY) THEN
              VALIDATE("Bill-to Customer Template Code",Cont.FindCustomerTemplate);
          END ELSE
            ERROR(Text039,Cont."No.",Cont.Name);
        END;
    end;

    local procedure UpdateSellToCustTemplateCode();
    begin
        IF ("Document Type" = "Document Type"::Quote) AND ("Sell-to Customer No." = '') AND ("Sell-to Customer Template Code" = '' ) AND
           (GetFilterContNo = '')
        THEN
          VALIDATE("Sell-to Customer Template Code",SelectSalesHeaderCustomerTemplate);
    end;

    local procedure GetShippingTime(CalledByFieldNo : Integer);
    var
        ShippingAgentServices : Record "5790";
    begin
        IF (CalledByFieldNo <> CurrFieldNo) AND (CurrFieldNo <> 0) THEN
          EXIT;

        IF ShippingAgentServices.GET("Shipping Agent Code","Shipping Agent Service Code") THEN
          "Shipping Time" := ShippingAgentServices."Shipping Time"
        ELSE BEGIN
          GetCust("Sell-to Customer No.");
          "Shipping Time" := Cust."Shipping Time"
        END;
        IF NOT (CalledByFieldNo IN [FIELDNO("Shipping Agent Code"),FIELDNO("Shipping Agent Service Code")]) THEN
          VALIDATE("Shipping Time");
    end;

    [Scope('Internal')]
    procedure CheckCreditMaxBeforeInsert();
    var
        SalesHeader : Record "36";
        ContBusinessRelation : Record "5054";
        Cont : Record "5050";
        CustCheckCreditLimit : Codeunit "312";
    begin
        IF HideCreditCheckDialogue THEN
          EXIT;
        IF (GetFilterCustNo <> '') OR ("Sell-to Customer No." <> '') THEN BEGIN
          IF "Sell-to Customer No." <> '' THEN
            Cust.GET("Sell-to Customer No.")
          ELSE
            Cust.GET(GetFilterCustNo);
          IF Cust."Bill-to Customer No." <> '' THEN
            SalesHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
          ELSE
            SalesHeader."Bill-to Customer No." := Cust."No.";
          CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
        END ELSE
          IF GetFilterContNo <> '' THEN BEGIN
            Cont.GET(GetFilterContNo);
            IF ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer,Cont."Company No.") THEN BEGIN
              Cust.GET(ContBusinessRelation."No.");
              IF Cust."Bill-to Customer No." <> '' THEN
                SalesHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
              ELSE
                SalesHeader."Bill-to Customer No." := Cust."No.";
              CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
            END;
          END;
    end;

    [Scope('Personalization')]
    procedure CreateInvtPutAwayPick();
    var
        WhseRequest : Record "5765";
    begin
        IF "Document Type" = "Document Type"::Order THEN
          IF NOT IsApprovedForPosting THEN
            EXIT;
        TESTFIELD(Status,Status::Released);

        WhseRequest.RESET;
        WhseRequest.SETCURRENTKEY("Source Document","Source No.");
        CASE "Document Type" OF
          "Document Type"::Order:
            BEGIN
              IF "Shipping Advice" = "Shipping Advice"::Complete THEN
                CheckShippingAdvice;
              WhseRequest.SETRANGE("Source Document",WhseRequest."Source Document"::"Sales Order");
            END;
          "Document Type"::"Return Order":
            WhseRequest.SETRANGE("Source Document",WhseRequest."Source Document"::"Sales Return Order");
        END;
        WhseRequest.SETRANGE("Source No.","No.");
        REPORT.RUNMODAL(REPORT::"Create Invt Put-away/Pick/Mvmt",TRUE,FALSE,WhseRequest);
    end;

    [Scope('Personalization')]
    procedure CreateTask();
    var
        TempTask : Record "5080" temporary;
    begin
        TESTFIELD("Sell-to Contact No.");
        TempTask.CreateTaskFromSalesHeader(Rec);
    end;

    [Scope('Personalization')]
    procedure UpdateShipToAddress();
    begin
        IF IsCreditDocType THEN
          IF "Location Code" <> '' THEN BEGIN
            Location.GET("Location Code");
            SetShipToAddress(
              Location.Name,Location."Name 2",Location.Address,Location."Address 2",Location.City,
              Location."Post Code",Location.County,Location."Country/Region Code");
            "Ship-to Contact" := Location.Contact;
          END ELSE BEGIN
            CompanyInfo.GET;
            "Ship-to Code" := '';
            SetShipToAddress(
              CompanyInfo."Ship-to Name",CompanyInfo."Ship-to Name 2",CompanyInfo."Ship-to Address",CompanyInfo."Ship-to Address 2",
              CompanyInfo."Ship-to City",CompanyInfo."Ship-to Post Code",CompanyInfo."Ship-to County",
              CompanyInfo."Ship-to Country/Region Code");
            "Ship-to Contact" := CompanyInfo."Ship-to Contact";
          END;

        OnAfterUpdateShipToAddress(Rec);
    end;

    [Scope('Personalization')]
    procedure ShowDocDim();
    var
        OldDimSetID : Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet2(
            "Dimension Set ID",STRSUBSTNO('%1 %2',"Document Type","No."),
            "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
        IF OldDimSetID <> "Dimension Set ID" THEN BEGIN
          MODIFY;
          IF SalesLinesExist THEN
            UpdateAllLineDim("Dimension Set ID",OldDimSetID);
        END;
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID : Integer;OldParentDimSetID : Integer);
    var
        ATOLink : Record "904";
        NewDimSetID : Integer;
        ShippedReceivedItemLineDimChangeConfirmed : Boolean;
    begin
        // Update all lines with changed dimensions.

        IF NewParentDimSetID = OldParentDimSetID THEN
          EXIT;
        IF NOT GetHideValidationDialog AND GUIALLOWED THEN
          IF NOT CONFIRM(Text064) THEN
            EXIT;

        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.LOCKTABLE;
        IF SalesLine.FIND('-') THEN
          REPEAT
            NewDimSetID := DimMgt.GetDeltaDimSetID(SalesLine."Dimension Set ID",NewParentDimSetID,OldParentDimSetID);
            IF SalesLine."Dimension Set ID" <> NewDimSetID THEN BEGIN
              SalesLine."Dimension Set ID" := NewDimSetID;

              IF NOT GetHideValidationDialog AND GUIALLOWED THEN
                VerifyShippedReceivedItemLineDimChange(ShippedReceivedItemLineDimChangeConfirmed);

              DimMgt.UpdateGlobalDimFromDimSetID(
                SalesLine."Dimension Set ID",SalesLine."Shortcut Dimension 1 Code",SalesLine."Shortcut Dimension 2 Code");
              SalesLine.MODIFY;
              ATOLink.UpdateAsmDimFromSalesLine(SalesLine);
            END;
          UNTIL SalesLine.NEXT = 0;
    end;

    local procedure VerifyShippedReceivedItemLineDimChange(var ShippedReceivedItemLineDimChangeConfirmed : Boolean);
    begin
        IF SalesLine.IsShippedReceivedItemDimChanged THEN
          IF NOT ShippedReceivedItemLineDimChangeConfirmed THEN
            ShippedReceivedItemLineDimChangeConfirmed := SalesLine.ConfirmShippedReceivedItemDimChange;
    end;

    [Scope('Personalization')]
    procedure LookupAdjmtValueEntries(QtyType : Option General,Invoicing);
    var
        ItemLedgEntry : Record "32";
        SalesLine : Record "37";
        SalesShptLine : Record "111";
        ReturnRcptLine : Record "6661";
        TempValueEntry : Record "5802" temporary;
    begin
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        TempValueEntry.RESET;
        TempValueEntry.DELETEALL;

        CASE "Document Type" OF
          "Document Type"::Order,"Document Type"::Invoice:
            BEGIN
              IF SalesLine.FINDSET THEN
                REPEAT
                  IF (SalesLine.Type = SalesLine.Type::Item) AND (SalesLine.Quantity <> 0) THEN
                    WITH SalesShptLine DO BEGIN
                      IF SalesLine."Shipment No." <> '' THEN BEGIN
                        SETRANGE("Document No.",SalesLine."Shipment No.");
                        SETRANGE("Line No.",SalesLine."Shipment Line No.");
                      END ELSE BEGIN
                        SETCURRENTKEY("Order No.","Order Line No.");
                        SETRANGE("Order No.",SalesLine."Document No.");
                        SETRANGE("Order Line No.",SalesLine."Line No.");
                      END;
                      SETRANGE(Correction,FALSE);
                      IF QtyType = QtyType::Invoicing THEN
                        SETFILTER("Qty. Shipped Not Invoiced",'<>0');

                      IF FINDSET THEN
                        REPEAT
                          FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                          IF ItemLedgEntry.FINDSET THEN
                            REPEAT
                              CreateTempAdjmtValueEntries(TempValueEntry,ItemLedgEntry."Entry No.");
                            UNTIL ItemLedgEntry.NEXT = 0;
                        UNTIL NEXT = 0;
                    END;
                UNTIL SalesLine.NEXT = 0;
            END;
          "Document Type"::"Return Order","Document Type"::"Credit Memo":
            BEGIN
              IF SalesLine.FINDSET THEN
                REPEAT
                  IF (SalesLine.Type = SalesLine.Type::Item) AND (SalesLine.Quantity <> 0) THEN
                    WITH ReturnRcptLine DO BEGIN
                      IF SalesLine."Return Receipt No." <> '' THEN BEGIN
                        SETRANGE("Document No.",SalesLine."Return Receipt No.");
                        SETRANGE("Line No.",SalesLine."Return Receipt Line No.");
                      END ELSE BEGIN
                        SETCURRENTKEY("Return Order No.","Return Order Line No.");
                        SETRANGE("Return Order No.",SalesLine."Document No.");
                        SETRANGE("Return Order Line No.",SalesLine."Line No.");
                      END;
                      SETRANGE(Correction,FALSE);
                      IF QtyType = QtyType::Invoicing THEN
                        SETFILTER("Return Qty. Rcd. Not Invd.",'<>0');

                      IF FINDSET THEN
                        REPEAT
                          FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                          IF ItemLedgEntry.FINDSET THEN
                            REPEAT
                              CreateTempAdjmtValueEntries(TempValueEntry,ItemLedgEntry."Entry No.");
                            UNTIL ItemLedgEntry.NEXT = 0;
                        UNTIL NEXT = 0;
                    END;
                UNTIL SalesLine.NEXT = 0;
            END;
        END;
        PAGE.RUNMODAL(0,TempValueEntry);
    end;

    [Scope('Personalization')]
    procedure GetCustomerVATRegistrationNumber() : Text;
    begin
        EXIT("VAT Registration No.");
    end;

    [Scope('Personalization')]
    procedure GetCustomerVATRegistrationNumberLbl() : Text;
    begin
        EXIT(FIELDCAPTION("VAT Registration No."));
    end;

    [Scope('Personalization')]
    procedure GetCustomerGlobalLocationNumber() : Text;
    begin
        EXIT('');
    end;

    [Scope('Personalization')]
    procedure GetCustomerGlobalLocationNumberLbl() : Text;
    begin
        EXIT('');
    end;

    local procedure CreateTempAdjmtValueEntries(var TempValueEntry : Record "5802" temporary;ItemLedgEntryNo : Integer);
    var
        ValueEntry : Record "5802";
    begin
        WITH ValueEntry DO BEGIN
          SETCURRENTKEY("Item Ledger Entry No.");
          SETRANGE("Item Ledger Entry No.",ItemLedgEntryNo);
          IF FINDSET THEN
            REPEAT
              IF Adjustment THEN BEGIN
                TempValueEntry := ValueEntry;
                IF TempValueEntry.INSERT THEN;
              END;
            UNTIL NEXT = 0;
        END;
    end;

    [Scope('Internal')]
    procedure GetPstdDocLinesToRevere();
    var
        SalesPostedDocLines : Page "5850";
    begin
        GetCust("Sell-to Customer No.");
        SalesPostedDocLines.SetToSalesHeader(Rec);
        SalesPostedDocLines.SETRECORD(Cust);
        SalesPostedDocLines.LOOKUPMODE := TRUE;
        IF SalesPostedDocLines.RUNMODAL = ACTION::LookupOK THEN
          SalesPostedDocLines.CopyLineToDoc;

        CLEAR(SalesPostedDocLines);
    end;

    [Scope('Internal')]
    procedure CalcInvDiscForHeader();
    var
        SalesInvDisc : Codeunit "60";
    begin
        SalesSetup.GET;
        IF SalesSetup."Calc. Inv. Discount" THEN
          SalesInvDisc.CalculateIncDiscForHeader(Rec);
    end;

    [Scope('Personalization')]
    procedure SetSecurityFilterOnRespCenter();
    begin
        IF UserSetupMgt.GetSalesFilter <> '' THEN BEGIN
          FILTERGROUP(2);
          SETRANGE("Responsibility Center",UserSetupMgt.GetSalesFilter);
          FILTERGROUP(0);
        END;

        SETRANGE("Date Filter",0D,WORKDATE - 1);
    end;

    local procedure SynchronizeForReservations(var NewSalesLine : Record "37";OldSalesLine : Record "37");
    begin
        NewSalesLine.CALCFIELDS("Reserved Quantity");
        IF NewSalesLine."Reserved Quantity" = 0 THEN
          EXIT;
        IF NewSalesLine."Location Code" <> OldSalesLine."Location Code" THEN
          NewSalesLine.VALIDATE("Location Code",OldSalesLine."Location Code");
        IF NewSalesLine."Bin Code" <> OldSalesLine."Bin Code" THEN
          NewSalesLine.VALIDATE("Bin Code",OldSalesLine."Bin Code");
        IF NewSalesLine.MODIFY THEN;
    end;

    [Scope('Personalization')]
    procedure InventoryPickConflict(DocType : Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";DocNo : Code[20];ShippingAdvice : Option Partial,Complete) : Boolean;
    var
        WarehouseActivityLine : Record "5767";
        SalesLine : Record "37";
    begin
        IF ShippingAdvice <> ShippingAdvice::Complete THEN
          EXIT(FALSE);
        WarehouseActivityLine.SETCURRENTKEY("Source Type","Source Subtype","Source No.");
        WarehouseActivityLine.SETRANGE("Source Type",DATABASE::"Sales Line");
        WarehouseActivityLine.SETRANGE("Source Subtype",DocType);
        WarehouseActivityLine.SETRANGE("Source No.",DocNo);
        IF WarehouseActivityLine.ISEMPTY THEN
          EXIT(FALSE);
        SalesLine.SETRANGE("Document Type",DocType);
        SalesLine.SETRANGE("Document No.",DocNo);
        SalesLine.SETRANGE(Type,SalesLine.Type::Item);
        IF SalesLine.ISEMPTY THEN
          EXIT(FALSE);
        EXIT(TRUE);
    end;

    [Scope('Personalization')]
    procedure WhseShpmntConflict(DocType : Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";DocNo : Code[20];ShippingAdvice : Option Partial,Complete) : Boolean;
    var
        WarehouseShipmentLine : Record "7321";
    begin
        IF ShippingAdvice <> ShippingAdvice::Complete THEN
          EXIT(FALSE);
        WarehouseShipmentLine.SETCURRENTKEY("Source Type","Source Subtype","Source No.","Source Line No.");
        WarehouseShipmentLine.SETRANGE("Source Type",DATABASE::"Sales Line");
        WarehouseShipmentLine.SETRANGE("Source Subtype",DocType);
        WarehouseShipmentLine.SETRANGE("Source No.",DocNo);
        IF WarehouseShipmentLine.ISEMPTY THEN
          EXIT(FALSE);
        EXIT(TRUE);
    end;

    local procedure CheckCrLimit();
    var
        SalesHeader : Record "36";
    begin
        SalesHeader := Rec;

        IF GUIALLOWED AND
           (CurrFieldNo <> 0) AND
           (("Document Type" <= "Document Type"::Invoice) OR ("Document Type" = "Document Type"::"Blanket Order")) AND
           SalesHeader.FIND
        THEN BEGIN
          "Amount Including VAT" := 0;
          IF "Document Type" = "Document Type"::Order THEN
            IF BilltoCustomerNoChanged THEN BEGIN
              SalesLine.SETRANGE("Document Type",SalesLine."Document Type"::Order);
              SalesLine.SETRANGE("Document No.","No.");
              SalesLine.CALCSUMS("Outstanding Amount","Shipped Not Invoiced");
              "Amount Including VAT" := SalesLine."Outstanding Amount" + SalesLine."Shipped Not Invoiced";
            END;
          CustCheckCreditLimit.SalesHeaderCheck(Rec);
          CALCFIELDS("Amount Including VAT");
        END;
    end;

    procedure CheckItemAvailabilityInLines();
    var
        SalesLine : Record "37";
        ItemCheckAvail : Codeunit "311";
    begin
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETRANGE(Type,SalesLine.Type::Item);
        SalesLine.SETFILTER("No.",'<>%1','');
        SalesLine.SETFILTER("Outstanding Quantity",'<>%1',0);
        IF SalesLine.FINDSET THEN
          REPEAT
            IF ItemCheckAvail.SalesLineCheck(SalesLine) THEN
              ItemCheckAvail.RaiseUpdateInterruptedError;
          UNTIL SalesLine.NEXT = 0;
    end;

    [Scope('Personalization')]
    procedure QtyToShipIsZero() : Boolean;
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER("Qty. to Ship",'<>0');
        EXIT(SalesLine.ISEMPTY);
    end;

    [Scope('Internal')]
    procedure IsApprovedForPosting() : Boolean;
    var
        PrepaymentMgt : Codeunit "441";
    begin
        IF ApprovalsMgmt.PrePostApprovalCheckSales(Rec) THEN BEGIN
          IF PrepaymentMgt.TestSalesPrepayment(Rec) THEN
            ERROR(STRSUBSTNO(PrepaymentInvoicesNotPaidErr,"Document Type","No."));
          IF "Document Type" = "Document Type"::Order THEN
            IF PrepaymentMgt.TestSalesPayment(Rec) THEN
              ERROR(STRSUBSTNO(Text072,"Document Type","No."));
          EXIT(TRUE);
        END;
    end;

    [Scope('Personalization')]
    procedure IsApprovedForPostingBatch() : Boolean;
    var
        PrepaymentMgt : Codeunit "441";
    begin
        IF ApprovalsMgmt.PrePostApprovalCheckSales(Rec) THEN BEGIN
          IF PrepaymentMgt.TestSalesPrepayment(Rec) THEN
            EXIT(FALSE);
          IF PrepaymentMgt.TestSalesPayment(Rec) THEN
            EXIT(FALSE);
          EXIT(TRUE);
        END;
    end;

    [Scope('Personalization')]
    procedure GetLegalStatement() : Text;
    begin
        SalesSetup.GET;
        EXIT(SalesSetup.GetLegalStatement);
    end;

    [Scope('Personalization')]
    procedure SendToPosting(PostingCodeunitID : Integer);
    begin
        IF NOT IsApprovedForPosting THEN
          EXIT;
        CODEUNIT.RUN(PostingCodeunitID,Rec);
    end;

    [Scope('Personalization')]
    procedure CancelBackgroundPosting();
    var
        SalesPostViaJobQueue : Codeunit "88";
    begin
        SalesPostViaJobQueue.CancelQueueEntry(Rec);
    end;

    [Scope('Internal')]
    procedure EmailRecords(ShowDialog : Boolean);
    var
        DocumentSendingProfile : Record "60";
        DummyReportSelections : Record "77";
    begin
        CASE "Document Type" OF
          "Document Type"::Quote:
            BEGIN
              DocumentSendingProfile.TrySendToEMail(
                DummyReportSelections.Usage::"S.Quote",Rec,FIELDNO("No."),
                GetDocTypeTxt,FIELDNO("Bill-to Customer No."),ShowDialog);
              FIND;
              "Quote Sent to Customer" := CURRENTDATETIME;
              MODIFY;
            END;
          "Document Type"::Invoice:
            DocumentSendingProfile.TrySendToEMail(
              DummyReportSelections.Usage::"S.Invoice Draft",Rec,FIELDNO("No."),
              GetDocTypeTxt,FIELDNO("Bill-to Customer No."),ShowDialog);
        END;

        OnAfterSendSalesHeader(Rec,ShowDialog);
    end;

    procedure GetDocTypeTxt() : Text[50];
    var
        IdentityManagement : Codeunit "9801";
    begin
        IF "Document Type" = "Document Type"::Quote THEN
          IF IdentityManagement.IsInvAppId THEN
            EXIT(EstimateTxt);
        EXIT(FORMAT("Document Type"));
    end;

    [Scope('Personalization')]
    procedure LinkSalesDocWithOpportunity(OldOpportunityNo : Code[20]);
    var
        SalesHeader : Record "36";
        Opportunity : Record "5092";
    begin
        IF "Opportunity No." <> OldOpportunityNo THEN BEGIN
          IF "Opportunity No." <> '' THEN
            IF Opportunity.GET("Opportunity No.") THEN BEGIN
              Opportunity.TESTFIELD(Status,Opportunity.Status::"In Progress");
              IF Opportunity."Sales Document No." <> '' THEN BEGIN
                IF CONFIRM(Text048,FALSE,Opportunity."Sales Document No.",Opportunity."No.") THEN BEGIN
                  IF SalesHeader.GET("Document Type"::Quote,Opportunity."Sales Document No.") THEN BEGIN
                    SalesHeader."Opportunity No." := '';
                    SalesHeader.MODIFY;
                  END;
                  UpdateOpportunityLink(Opportunity,Opportunity."Sales Document Type"::Quote,"No.");
                END ELSE
                  "Opportunity No." := OldOpportunityNo;
              END ELSE
                UpdateOpportunityLink(Opportunity,Opportunity."Sales Document Type"::Quote,"No.");
            END;
          IF (OldOpportunityNo <> '') AND Opportunity.GET(OldOpportunityNo) THEN
            UpdateOpportunityLink(Opportunity,Opportunity."Sales Document Type"::" ",'');
        END;
    end;

    local procedure UpdateOpportunityLink(Opportunity : Record "5092";SalesDocumentType : Option;SalesHeaderNo : Code[20]);
    begin
        Opportunity."Sales Document Type" := SalesDocumentType;
        Opportunity."Sales Document No." := SalesHeaderNo;
        Opportunity.MODIFY;
    end;

    procedure SynchronizeAsmHeader();
    var
        AsmHeader : Record "900";
        ATOLink : Record "904";
        Window : Dialog;
    begin
        ATOLink.SETCURRENTKEY(Type,"Document Type","Document No.");
        ATOLink.SETRANGE(Type,ATOLink.Type::Sale);
        ATOLink.SETRANGE("Document Type","Document Type");
        ATOLink.SETRANGE("Document No.","No.");
        IF ATOLink.FINDSET THEN
          REPEAT
            IF AsmHeader.GET(ATOLink."Assembly Document Type",ATOLink."Assembly Document No.") THEN
              IF "Posting Date" <> AsmHeader."Posting Date" THEN BEGIN
                Window.OPEN(STRSUBSTNO(SynchronizingMsg,"No.",AsmHeader."No."));
                AsmHeader.VALIDATE("Posting Date","Posting Date");
                AsmHeader.MODIFY;
                Window.CLOSE;
              END;
          UNTIL ATOLink.NEXT = 0;
    end;

    [Scope('Personalization')]
    procedure CheckShippingAdvice();
    var
        SalesLine : Record "37";
        QtyToShipBaseTotal : Decimal;
        Result : Boolean;
    begin
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETRANGE("Drop Shipment",FALSE);
        Result := TRUE;
        IF SalesLine.FINDSET THEN
          REPEAT
            IF SalesLine.IsShipment THEN BEGIN
              QtyToShipBaseTotal += SalesLine."Qty. to Ship (Base)";
              IF SalesLine."Quantity (Base)" <>
                 SalesLine."Qty. to Ship (Base)" + SalesLine."Qty. Shipped (Base)"
              THEN
                Result := FALSE;
            END;
          UNTIL SalesLine.NEXT = 0;
        IF QtyToShipBaseTotal = 0 THEN
          Result := TRUE;
        IF NOT Result THEN
          ERROR(ShippingAdviceErr);
    end;

    local procedure GetFilterCustNo() : Code[20];
    var
        MinValue : Code[20];
        MaxValue : Code[20];
    begin
        IF GETFILTER("Sell-to Customer No.") <> '' THEN BEGIN
          IF TryGetFilterCustNoRange(MinValue,MaxValue) THEN
            IF MinValue = MaxValue THEN
              EXIT(MaxValue);
        END;
    end;

    [TryFunction]
    local procedure TryGetFilterCustNoRange(var MinValue : Code[20];var MaxValue : Code[20]);
    begin
        MinValue := GETRANGEMIN("Sell-to Customer No.");
        MaxValue := GETRANGEMAX("Sell-to Customer No.");
    end;

    local procedure GetFilterCustNoByApplyingFilter() : Code[20];
    var
        SalesHeader : Record "36";
        MinValue : Code[20];
        MaxValue : Code[20];
    begin
        IF GETFILTER("Sell-to Customer No.") <> '' THEN BEGIN
          SalesHeader.COPYFILTERS(Rec);
          SalesHeader.SETCURRENTKEY("Sell-to Customer No.");
          IF SalesHeader.FINDFIRST THEN
            MinValue := SalesHeader."Sell-to Customer No.";
          IF SalesHeader.FINDLAST THEN
            MaxValue := SalesHeader."Sell-to Customer No.";
          IF MinValue = MaxValue THEN
            EXIT(MaxValue);
        END;
    end;

    local procedure GetFilterContNo() : Code[20];
    begin
        IF GETFILTER("Sell-to Contact No.") <> '' THEN
          IF GETRANGEMIN("Sell-to Contact No.") = GETRANGEMAX("Sell-to Contact No.") THEN
            EXIT(GETRANGEMAX("Sell-to Contact No."));
    end;

    local procedure CheckCreditLimitIfLineNotInsertedYet();
    begin
        IF "No." = '' THEN BEGIN
          HideCreditCheckDialogue := FALSE;
          CheckCreditMaxBeforeInsert;
          HideCreditCheckDialogue := TRUE;
        END;
    end;

    [Scope('Personalization')]
    procedure InvoicedLineExists() : Boolean;
    var
        SalesLine : Record "37";
    begin
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER(Type,'<>%1',SalesLine.Type::" ");
        SalesLine.SETFILTER("Quantity Invoiced",'<>%1',0);
        EXIT(NOT SalesLine.ISEMPTY);
    end;

    [Scope('Personalization')]
    procedure CreateDimSetForPrepmtAccDefaultDim();
    var
        SalesLine : Record "37";
        TempSalesLine : Record "37" temporary;
    begin
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        SalesLine.SETFILTER("Prepmt. Amt. Inv.",'<>%1',0);
        IF SalesLine.FINDSET THEN
          REPEAT
            CollectParamsInBufferForCreateDimSet(TempSalesLine,SalesLine);
          UNTIL SalesLine.NEXT = 0;
        TempSalesLine.RESET;
        TempSalesLine.MARKEDONLY(FALSE);
        IF TempSalesLine.FINDSET THEN
          REPEAT
            SalesLine.CreateDim(DATABASE::"G/L Account",TempSalesLine."No.",
              DATABASE::Job,TempSalesLine."Job No.",
              DATABASE::"Responsibility Center",TempSalesLine."Responsibility Center");
          UNTIL TempSalesLine.NEXT = 0;
    end;

    local procedure CollectParamsInBufferForCreateDimSet(var TempSalesLine : Record "37" temporary;SalesLine : Record "37");
    var
        GenPostingSetup : Record "252";
        DefaultDimension : Record "352";
    begin
        TempSalesLine.SETRANGE("Gen. Bus. Posting Group",SalesLine."Gen. Bus. Posting Group");
        TempSalesLine.SETRANGE("Gen. Prod. Posting Group",SalesLine."Gen. Prod. Posting Group");
        IF NOT TempSalesLine.FINDFIRST THEN BEGIN
          GenPostingSetup.GET(SalesLine."Gen. Bus. Posting Group",SalesLine."Gen. Prod. Posting Group");
          DefaultDimension.SETRANGE("Table ID",DATABASE::"G/L Account");
          DefaultDimension.SETRANGE("No.",GenPostingSetup.GetSalesPrepmtAccount);
          InsertTempSalesLineInBuffer(TempSalesLine,SalesLine,GenPostingSetup."Sales Prepayments Account",DefaultDimension.ISEMPTY);
        END ELSE
          IF NOT TempSalesLine.MARK THEN BEGIN
            TempSalesLine.SETRANGE("Job No.",SalesLine."Job No.");
            TempSalesLine.SETRANGE("Responsibility Center",SalesLine."Responsibility Center");
            IF TempSalesLine.ISEMPTY THEN
              InsertTempSalesLineInBuffer(TempSalesLine,SalesLine,TempSalesLine."No.",FALSE);
          END;
    end;

    local procedure InsertTempSalesLineInBuffer(var TempSalesLine : Record "37" temporary;SalesLine : Record "37";AccountNo : Code[20];DefaultDimensionsNotExist : Boolean);
    begin
        TempSalesLine.INIT;
        TempSalesLine."Line No." := SalesLine."Line No.";
        TempSalesLine."No." := AccountNo;
        TempSalesLine."Job No." := SalesLine."Job No.";
        TempSalesLine."Responsibility Center" := SalesLine."Responsibility Center";
        TempSalesLine."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        TempSalesLine."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        TempSalesLine.MARK := DefaultDimensionsNotExist;
        TempSalesLine.INSERT;
    end;

    [Scope('Internal')]
    procedure OpenSalesOrderStatistics();
    begin
        CalcInvDiscForHeader;
        CreateDimSetForPrepmtAccDefaultDim;
        COMMIT;
        PAGE.RUNMODAL(PAGE::"Sales Order Statistics",Rec);
    end;

    [Scope('Personalization')]
    procedure GetCardpageID() : Integer;
    begin
        CASE "Document Type" OF
          "Document Type"::Quote:
            EXIT(PAGE::"Sales Quote");
          "Document Type"::Order:
            EXIT(PAGE::"Sales Order");
          "Document Type"::Invoice:
            EXIT(PAGE::"Sales Invoice");
          "Document Type"::"Credit Memo":
            EXIT(PAGE::"Sales Credit Memo");
          "Document Type"::"Blanket Order":
            EXIT(PAGE::"Blanket Sales Order");
          "Document Type"::"Return Order":
            EXIT(PAGE::"Sales Return Order");
        END;
    end;

    [Scope('Personalization')]
    procedure CheckAvailableCreditLimit() : Decimal;
    var
        Customer : Record "18";
        AvailableCreditLimit : Decimal;
    begin
        IF NOT Customer.GET("Bill-to Customer No.") THEN
          Customer.GET("Sell-to Customer No.");

        AvailableCreditLimit := Customer.CalcAvailableCredit;

        IF AvailableCreditLimit < 0 THEN
          OnCustomerCreditLimitExceeded
        ELSE
          OnCustomerCreditLimitNotExceeded;

        EXIT(AvailableCreditLimit);
    end;

    [Scope('Personalization')]
    procedure SetStatus(NewStatus : Option);
    begin
        Status := NewStatus;
        MODIFY;
    end;

    local procedure TestSalesLineFieldsBeforeRecreate();
    begin
        SalesLine.TESTFIELD("Job No.",'');
        SalesLine.TESTFIELD("Job Contract Entry No.",0);
        SalesLine.TESTFIELD("Quantity Shipped",0);
        SalesLine.TESTFIELD("Quantity Invoiced",0);
        SalesLine.TESTFIELD("Return Qty. Received",0);
        SalesLine.TESTFIELD("Shipment No.",'');
        SalesLine.TESTFIELD("Return Receipt No.",'');
        SalesLine.TESTFIELD("Blanket Order No.",'');
        SalesLine.TESTFIELD("Prepmt. Amt. Inv.",0);
    end;

    local procedure RecreateReservEntryReqLine(var TempSalesLine : Record "37" temporary;var TempATOLink : Record "904" temporary;var ATOLink : Record "904");
    begin
        REPEAT
          TestSalesLineFieldsBeforeRecreate;
          IF (SalesLine."Location Code" <> "Location Code") AND NOT SalesLine.IsServiceItem THEN
            SalesLine.VALIDATE("Location Code","Location Code");
          TempSalesLine := SalesLine;
          IF SalesLine.Nonstock THEN BEGIN
            SalesLine.Nonstock := FALSE;
            SalesLine.MODIFY;
          END;

          IF ATOLink.AsmExistsForSalesLine(TempSalesLine) THEN BEGIN
            TempATOLink := ATOLink;
            TempATOLink.INSERT;
            ATOLink.DELETE;
          END;

          TempSalesLine.INSERT;
          CopyReservEntryToTemp(SalesLine);
          RecreateReqLine(SalesLine,0,TRUE);
        UNTIL SalesLine.NEXT = 0;
    end;

    local procedure TransferItemChargeAssgntSalesToTemp(var ItemChargeAssgntSales : Record "5809";var TempItemChargeAssgntSales : Record "5809" temporary);
    begin
        IF ItemChargeAssgntSales.FINDSET THEN BEGIN
          REPEAT
            TempItemChargeAssgntSales.INIT;
            TempItemChargeAssgntSales := ItemChargeAssgntSales;
            TempItemChargeAssgntSales.INSERT;
          UNTIL ItemChargeAssgntSales.NEXT = 0;
          ItemChargeAssgntSales.DELETEALL;
        END;
    end;

    local procedure CreateSalesLine(var TempSalesLine : Record "37" temporary);
    begin
        SalesLine.INIT;
        SalesLine."Line No." := SalesLine."Line No." + 10000;
        SalesLine.VALIDATE(Type,TempSalesLine.Type);
        IF TempSalesLine."No." = '' THEN BEGIN
          SalesLine.VALIDATE(Description,TempSalesLine.Description);
          SalesLine.VALIDATE("Description 2",TempSalesLine."Description 2");
        END ELSE BEGIN
          SalesLine.VALIDATE("No.",TempSalesLine."No.");
          IF SalesLine.Type <> SalesLine.Type::" " THEN BEGIN
            SalesLine.VALIDATE("Unit of Measure Code",TempSalesLine."Unit of Measure Code");
            SalesLine.VALIDATE("Variant Code",TempSalesLine."Variant Code");
            IF TempSalesLine.Quantity <> 0 THEN BEGIN
              SalesLine.VALIDATE(Quantity,TempSalesLine.Quantity);
              SalesLine.VALIDATE("Qty. to Assemble to Order",TempSalesLine."Qty. to Assemble to Order");
            END;
            SalesLine."Purchase Order No." := TempSalesLine."Purchase Order No.";
            SalesLine."Purch. Order Line No." := TempSalesLine."Purch. Order Line No.";
            SalesLine."Drop Shipment" := SalesLine."Purch. Order Line No." <> 0;
          END;
          SalesLine.VALIDATE("Shipment Date",TempSalesLine."Shipment Date");
        END;
        SalesLine.INSERT;
        OnAfterCreateSalesLine(SalesLine,TempSalesLine);
    end;

    local procedure CreateItemChargeAssgntSales(var ItemChargeAssgntSales : Record "5809";var TempItemChargeAssgntSales : Record "5809" temporary;var TempSalesLine : Record "37" temporary;var TempInteger : Record "2000000026" temporary);
    begin
        IF TempSalesLine.FINDSET THEN
          REPEAT
            TempItemChargeAssgntSales.SETRANGE("Document Line No.",TempSalesLine."Line No.");
            IF TempItemChargeAssgntSales.FINDSET THEN BEGIN
              REPEAT
                TempInteger.FINDFIRST;
                ItemChargeAssgntSales.INIT;
                ItemChargeAssgntSales := TempItemChargeAssgntSales;
                ItemChargeAssgntSales."Document Line No." := TempInteger.Number;
                ItemChargeAssgntSales.VALIDATE("Unit Cost",0);
                ItemChargeAssgntSales.INSERT;
              UNTIL TempItemChargeAssgntSales.NEXT = 0;
              TempInteger.DELETE;
            END;
          UNTIL TempSalesLine.NEXT = 0;
    end;

    local procedure UpdateOutboundWhseHandlingTime();
    begin
        IF "Location Code" <> '' THEN BEGIN
          IF Location.GET("Location Code") THEN
            "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
        END ELSE
          IF InvtSetup.GET THEN
            "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('Personalization')]
    procedure OnCheckSalesPostRestrictions();
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('Personalization')]
    procedure OnCustomerCreditLimitExceeded();
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('Personalization')]
    procedure OnCustomerCreditLimitNotExceeded();
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('Personalization')]
    procedure OnCheckSalesReleaseRestrictions();
    begin
    end;

    [Scope('Personalization')]
    procedure DeferralHeadersExist() : Boolean;
    var
        DeferralHeader : Record "1701";
        DeferralUtilities : Codeunit "1720";
    begin
        DeferralHeader.SETRANGE("Deferral Doc. Type",DeferralUtilities.GetSalesDeferralDocType);
        DeferralHeader.SETRANGE("Gen. Jnl. Template Name",'');
        DeferralHeader.SETRANGE("Gen. Jnl. Batch Name",'');
        DeferralHeader.SETRANGE("Document Type","Document Type");
        DeferralHeader.SETRANGE("Document No.","No.");
        EXIT(NOT DeferralHeader.ISEMPTY);
    end;

    [Scope('Personalization')]
    procedure SetSellToCustomerFromFilter();
    var
        SellToCustomerNo : Code[20];
    begin
        SellToCustomerNo := GetFilterCustNo;
        IF SellToCustomerNo = '' THEN BEGIN
          FILTERGROUP(2);
          SellToCustomerNo := GetFilterCustNo;
          IF SellToCustomerNo = '' THEN
            SellToCustomerNo := GetFilterCustNoByApplyingFilter;
          FILTERGROUP(0);
        END;
        IF SellToCustomerNo <> '' THEN
          VALIDATE("Sell-to Customer No.",SellToCustomerNo);
    end;

    [Scope('Personalization')]
    procedure CopySellToCustomerFilter();
    var
        SellToCustomerFilter : Text;
    begin
        SellToCustomerFilter := GETFILTER("Sell-to Customer No.");
        IF SellToCustomerFilter <> '' THEN BEGIN
          FILTERGROUP(2);
          SETFILTER("Sell-to Customer No.",SellToCustomerFilter);
          FILTERGROUP(0)
        END;
    end;

    local procedure ConfirmUpdateDeferralDate();
    begin
        IF GetHideValidationDialog THEN
          Confirmed := TRUE
        ELSE
          Confirmed := CONFIRM(DeferralLineQst,FALSE);
        IF Confirmed THEN
          UpdateSalesLines(SalesLine.FIELDCAPTION("Deferral Code"),FALSE);
    end;

    [Scope('Personalization')]
    procedure BatchConfirmUpdateDeferralDate(var BatchConfirm : Option " ",Skip,Update;ReplacePostingDate : Boolean;PostingDateReq : Date);
    begin
        IF (NOT ReplacePostingDate) OR (PostingDateReq = "Posting Date") OR (BatchConfirm = BatchConfirm::Skip) THEN
          EXIT;

        IF NOT DeferralHeadersExist THEN
          EXIT;

        "Posting Date" := PostingDateReq;
        CASE BatchConfirm OF
          BatchConfirm::" ":
            BEGIN
              ConfirmUpdateDeferralDate;
              IF Confirmed THEN
                BatchConfirm := BatchConfirm::Update
              ELSE
                BatchConfirm := BatchConfirm::Skip;
            END;
          BatchConfirm::Update:
            UpdateSalesLines(SalesLine.FIELDCAPTION("Deferral Code"),FALSE);
        END;
        COMMIT;
    end;

    [Scope('Personalization')]
    procedure GetSelectedPaymentServicesText() : Text;
    var
        PaymentServiceSetup : Record "1060";
    begin
        EXIT(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

    [Scope('Personalization')]
    procedure SetDefaultPaymentServices();
    var
        PaymentServiceSetup : Record "1060";
        SetID : Integer;
    begin
        IF NOT PaymentServiceSetup.CanChangePaymentService(Rec) THEN
          EXIT;

        IF PaymentServiceSetup.GetDefaultPaymentServices(SetID) THEN
          VALIDATE("Payment Service Set ID",SetID);
    end;

    [Scope('Personalization')]
    procedure ChangePaymentServiceSetting();
    var
        PaymentServiceSetup : Record "1060";
        SetID : Integer;
    begin
        SetID := "Payment Service Set ID";
        IF PaymentServiceSetup.SelectPaymentService(SetID) THEN BEGIN
          VALIDATE("Payment Service Set ID",SetID);
          MODIFY(TRUE);
        END;
    end;

    [Scope('Personalization')]
    procedure IsCreditDocType() : Boolean;
    begin
        EXIT("Document Type" IN ["Document Type"::"Return Order","Document Type"::"Credit Memo"]);
    end;

    [Scope('Personalization')]
    procedure HasSellToAddress() : Boolean;
    begin
        CASE TRUE OF
          "Sell-to Address" <> '':
            EXIT(TRUE);
          "Sell-to Address 2" <> '':
            EXIT(TRUE);
          "Sell-to City" <> '':
            EXIT(TRUE);
          "Sell-to Country/Region Code" <> '':
            EXIT(TRUE);
          "Sell-to County" <> '':
            EXIT(TRUE);
          "Sell-to Post Code" <> '':
            EXIT(TRUE);
          "Sell-to Contact" <> '':
            EXIT(TRUE);
        END;

        EXIT(FALSE);
    end;

    [Scope('Personalization')]
    procedure HasShipToAddress() : Boolean;
    begin
        CASE TRUE OF
          "Ship-to Address" <> '':
            EXIT(TRUE);
          "Ship-to Address 2" <> '':
            EXIT(TRUE);
          "Ship-to City" <> '':
            EXIT(TRUE);
          "Ship-to Country/Region Code" <> '':
            EXIT(TRUE);
          "Ship-to County" <> '':
            EXIT(TRUE);
          "Ship-to Post Code" <> '':
            EXIT(TRUE);
          "Ship-to Contact" <> '':
            EXIT(TRUE);
        END;

        EXIT(FALSE);
    end;

    [Scope('Personalization')]
    procedure HasBillToAddress() : Boolean;
    begin
        CASE TRUE OF
          "Bill-to Address" <> '':
            EXIT(TRUE);
          "Bill-to Address 2" <> '':
            EXIT(TRUE);
          "Bill-to City" <> '':
            EXIT(TRUE);
          "Bill-to Country/Region Code" <> '':
            EXIT(TRUE);
          "Bill-to County" <> '':
            EXIT(TRUE);
          "Bill-to Post Code" <> '':
            EXIT(TRUE);
          "Bill-to Contact" <> '':
            EXIT(TRUE);
        END;

        EXIT(FALSE);
    end;

    local procedure CopySellToCustomerAddressFieldsFromCustomer(var SellToCustomer : Record "18");
    begin
        IF SellToCustomerIsReplaced OR ShouldCopyAddressFromSellToCustomer(SellToCustomer) THEN BEGIN
          "Sell-to Address" := SellToCustomer.Address;
          "Sell-to Address 2" := SellToCustomer."Address 2";
          "Sell-to City" := SellToCustomer.City;
          "Sell-to Post Code" := SellToCustomer."Post Code";
          "Sell-to County" := SellToCustomer.County;
          "Sell-to Country/Region Code" := SellToCustomer."Country/Region Code";
        END;
    end;

    local procedure CopyShipToCustomerAddressFieldsFromCustomer(var SellToCustomer : Record "18");
    begin
        IF SellToCustomerIsReplaced OR ShipToAddressEqualsOldSellToAddress THEN BEGIN
          "Ship-to Address" := SellToCustomer.Address;
          "Ship-to Address 2" := SellToCustomer."Address 2";
          "Ship-to City" := SellToCustomer.City;
          "Ship-to Post Code" := SellToCustomer."Post Code";
          "Ship-to County" := SellToCustomer.County;
          VALIDATE("Ship-to Country/Region Code",SellToCustomer."Country/Region Code");
        END;
    end;

    local procedure CopyBillToCustomerAddressFieldsFromCustomer(var BillToCustomer : Record "18");
    begin
        IF BillToCustomerIsReplaced OR ShouldCopyAddressFromBillToCustomer(BillToCustomer) THEN BEGIN
          "Bill-to Address" := BillToCustomer.Address;
          "Bill-to Address 2" := BillToCustomer."Address 2";
          "Bill-to City" := BillToCustomer.City;
          "Bill-to Post Code" := BillToCustomer."Post Code";
          "Bill-to County" := BillToCustomer.County;
          "Bill-to Country/Region Code" := BillToCustomer."Country/Region Code";
        END;
    end;

    [Scope('Personalization')]
    procedure SetShipToAddress(ShipToName : Text[50];ShipToName2 : Text[50];ShipToAddress : Text[50];ShipToAddress2 : Text[50];ShipToCity : Text[30];ShipToPostCode : Code[20];ShipToCounty : Text[30];ShipToCountryRegionCode : Code[10]);
    begin
        "Ship-to Name" := ShipToName;
        "Ship-to Name 2" := ShipToName2;
        "Ship-to Address" := ShipToAddress;
        "Ship-to Address 2" := ShipToAddress2;
        "Ship-to City" := ShipToCity;
        "Ship-to Post Code" := ShipToPostCode;
        "Ship-to County" := ShipToCounty;
        "Ship-to Country/Region Code" := ShipToCountryRegionCode;
    end;

    local procedure ShouldCopyAddressFromSellToCustomer(SellToCustomer : Record "18") : Boolean;
    begin
        EXIT((NOT HasSellToAddress) AND SellToCustomer.HasAddress);
    end;

    local procedure ShouldCopyAddressFromBillToCustomer(BillToCustomer : Record "18") : Boolean;
    begin
        EXIT((NOT HasBillToAddress) AND BillToCustomer.HasAddress);
    end;

    local procedure SellToCustomerIsReplaced() : Boolean;
    begin
        EXIT((xRec."Sell-to Customer No." <> '') AND (xRec."Sell-to Customer No." <> "Sell-to Customer No."));
    end;

    local procedure BillToCustomerIsReplaced() : Boolean;
    begin
        EXIT((xRec."Bill-to Customer No." <> '') AND (xRec."Bill-to Customer No." <> "Bill-to Customer No."));
    end;

    local procedure UpdateShipToAddressFromSellToAddress(FieldNumber : Integer);
    begin
        IF ("Ship-to Code" = '') AND ShipToAddressEqualsOldSellToAddress THEN
          CASE FieldNumber OF
            FIELDNO("Ship-to Address"):
              "Ship-to Address" := "Sell-to Address";
            FIELDNO("Ship-to Address 2"):
              "Ship-to Address 2" := "Sell-to Address 2";
            FIELDNO("Ship-to City"),FIELDNO("Ship-to Post Code"):
              BEGIN
                "Ship-to City" := "Sell-to City";
                "Ship-to Post Code" := "Sell-to Post Code";
                "Ship-to County" := "Sell-to County";
                "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
              END;
            FIELDNO("Ship-to County"):
              "Ship-to County" := "Sell-to County";
            FIELDNO("Ship-to Country/Region Code"):
              "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
          END;
    end;

    local procedure ShipToAddressEqualsOldSellToAddress() : Boolean;
    begin
        EXIT(IsShipToAddressEqualToSellToAddress(xRec,Rec));
    end;

    [Scope('Personalization')]
    procedure ShipToAddressEqualsSellToAddress() : Boolean;
    begin
        EXIT(IsShipToAddressEqualToSellToAddress(Rec,Rec));
    end;

    local procedure IsShipToAddressEqualToSellToAddress(SalesHeaderWithSellTo : Record "36";SalesHeaderWithShipTo : Record "36") : Boolean;
    begin
        IF (SalesHeaderWithSellTo."Sell-to Address" = SalesHeaderWithShipTo."Ship-to Address") AND
           (SalesHeaderWithSellTo."Sell-to Address 2" = SalesHeaderWithShipTo."Ship-to Address 2") AND
           (SalesHeaderWithSellTo."Sell-to City" = SalesHeaderWithShipTo."Ship-to City") AND
           (SalesHeaderWithSellTo."Sell-to County" = SalesHeaderWithShipTo."Ship-to County") AND
           (SalesHeaderWithSellTo."Sell-to Post Code" = SalesHeaderWithShipTo."Ship-to Post Code") AND
           (SalesHeaderWithSellTo."Sell-to Country/Region Code" = SalesHeaderWithShipTo."Ship-to Country/Region Code") AND
           (SalesHeaderWithSellTo."Sell-to Contact" = SalesHeaderWithShipTo."Ship-to Contact")
        THEN
          EXIT(TRUE);
    end;

    [Scope('Personalization')]
    procedure CopySellToAddressToShipToAddress();
    begin
        VALIDATE("Ship-to Address","Sell-to Address");
        VALIDATE("Ship-to Address 2","Sell-to Address 2");
        VALIDATE("Ship-to City","Sell-to City");
        VALIDATE("Ship-to Contact","Sell-to Contact");
        VALIDATE("Ship-to Country/Region Code","Sell-to Country/Region Code");
        VALIDATE("Ship-to County","Sell-to County");
        VALIDATE("Ship-to Post Code","Sell-to Post Code");
    end;

    procedure CopySellToAddressToBillToAddress();
    begin
        IF "Bill-to Customer No." = "Sell-to Customer No." THEN BEGIN
          "Bill-to Address" := "Sell-to Address";
          "Bill-to Address 2" := "Sell-to Address 2";
          "Bill-to Post Code" := "Sell-to Post Code";
          "Bill-to Country/Region Code" := "Sell-to Country/Region Code";
          "Bill-to City" := "Sell-to City";
          "Bill-to County" := "Sell-to County";
        END;
    end;

    local procedure UpdateShipToContact();
    begin
        IF CurrFieldNo <> FIELDNO("Sell-to Contact") THEN
          EXIT;

        IF IsCreditDocType THEN
          EXIT;

        VALIDATE("Ship-to Contact","Sell-to Contact");
    end;

    [Scope('Personalization')]
    procedure ConfirmCloseUnposted() : Boolean;
    var
        InstructionMgt : Codeunit "1330";
    begin
        IF SalesLinesExist THEN
          EXIT(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst,InstructionMgt.QueryPostOnCloseCode));
        EXIT(TRUE)
    end;

    local procedure UpdateOpportunity();
    var
        Opp : Record "5092";
        OpportunityEntry : Record "5093";
    begin
        IF NOT ("Opportunity No." <> '') OR NOT ("Document Type" IN ["Document Type"::Quote,"Document Type"::Order]) THEN
          EXIT;

        IF NOT Opp.GET("Opportunity No.") THEN
          EXIT;

        IF "Document Type" = "Document Type"::Order THEN BEGIN
          IF NOT CONFIRM(Text040,TRUE) THEN
            ERROR(Text044);

          OpportunityEntry.SETRANGE("Opportunity No.","Opportunity No.");
          OpportunityEntry.MODIFYALL(Active,FALSE);

          OpportunityEntry.INIT;
          OpportunityEntry.VALIDATE("Opportunity No.",Opp."No.");

          OpportunityEntry.LOCKTABLE;
          OpportunityEntry."Entry No." := GetOpportunityEntryNo;
          OpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
          OpportunityEntry."Contact No." := Opp."Contact No.";
          OpportunityEntry."Contact Company No." := Opp."Contact Company No.";
          OpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
          OpportunityEntry."Campaign No." := Opp."Campaign No.";
          OpportunityEntry."Action Taken" := OpportunityEntry."Action Taken"::Lost;
          OpportunityEntry.Active := TRUE;
          OpportunityEntry."Completed %" := 100;
          OpportunityEntry."Estimated Value (LCY)" := GetOpportunityEntryEstimatedValue;
          OpportunityEntry."Estimated Close Date" := Opp."Date Closed";
          OpportunityEntry.INSERT(TRUE);
        END;
        Opp.FIND;
        Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
        Opp."Sales Document No." := '';
        Opp.MODIFY;
        "Opportunity No." := '';
    end;

    local procedure GetOpportunityEntryNo() : Integer;
    var
        OpportunityEntry : Record "5093";
    begin
        IF OpportunityEntry.FINDLAST THEN
          EXIT(OpportunityEntry."Entry No." + 1);
        EXIT(1);
    end;

    local procedure GetOpportunityEntryEstimatedValue() : Decimal;
    var
        OpportunityEntry : Record "5093";
    begin
        OpportunityEntry.SETRANGE("Opportunity No.","Opportunity No.");
        IF OpportunityEntry.FINDLAST THEN
          EXIT(OpportunityEntry."Estimated Value (LCY)");
    end;

    [Scope('Personalization')]
    procedure InitFromSalesHeader(SourceSalesHeader : Record "36");
    begin
        "Document Date" := SourceSalesHeader."Document Date";
        "Shipment Date" := SourceSalesHeader."Shipment Date";
        "Shortcut Dimension 1 Code" := SourceSalesHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SourceSalesHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SourceSalesHeader."Dimension Set ID";
        "Location Code" := SourceSalesHeader."Location Code";
        SetShipToAddress(
          SourceSalesHeader."Ship-to Name",SourceSalesHeader."Ship-to Name 2",SourceSalesHeader."Ship-to Address",
          SourceSalesHeader."Ship-to Address 2",SourceSalesHeader."Ship-to City",SourceSalesHeader."Ship-to Post Code",
          SourceSalesHeader."Ship-to County",SourceSalesHeader."Ship-to Country/Region Code");
        "Ship-to Contact" := SourceSalesHeader."Ship-to Contact";
    end;

    local procedure InitFromContact(ContactNo : Code[20];CustomerNo : Code[20];ContactCaption : Text) : Boolean;
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        IF (ContactNo = '') AND (CustomerNo = '') THEN BEGIN
          IF NOT SalesLine.ISEMPTY THEN
            ERROR(Text005,ContactCaption);
          INIT;
          SalesSetup.GET;
          "No. Series" := xRec."No. Series";
          InitRecord;
          InitNoSeries;
          EXIT(TRUE);
        END;
    end;

    local procedure InitFromTemplate(TemplateCode : Code[20];TemplateCaption : Text) : Boolean;
    begin
        SalesLine.RESET;
        SalesLine.SETRANGE("Document Type","Document Type");
        SalesLine.SETRANGE("Document No.","No.");
        IF TemplateCode = '' THEN BEGIN
          IF NOT SalesLine.ISEMPTY THEN
            ERROR(Text005,TemplateCaption);
          INIT;
          SalesSetup.GET;
          "No. Series" := xRec."No. Series";
          InitRecord;
          InitNoSeries;
          EXIT(TRUE);
        END;
    end;

    local procedure ValidateTaxAreaCode();
    var
        TaxArea : Record "318";
    begin
        IF "Tax Area Code" = '' THEN
          EXIT;
        IF NOT TaxArea.GET("Tax Area Code") THEN BEGIN
          TaxArea.SETFILTER(Code,"Tax Area Code" + '*');
          IF NOT TaxArea.FINDFIRST THEN
            TaxArea.CreateTaxArea("Tax Area Code","Sell-to City","Sell-to County");
          "Tax Area Code" := TaxArea.Code;
        END;

        IF Cust.GET("Sell-to Customer No.") THEN
          IF Cust."Tax Area Code" = '' THEN BEGIN
            Cust."Tax Area Code" := "Tax Area Code";
            Cust.MODIFY;
          END;
    end;

    [Scope('Personalization')]
    procedure SetWorkDescription(NewWorkDescription : Text);
    var
        TempBlob : Record "99008535" temporary;
    begin
        CLEAR("Work Description");
        IF NewWorkDescription = '' THEN
          EXIT;
        TempBlob.Blob := "Work Description";
        TempBlob.WriteAsText(NewWorkDescription,TEXTENCODING::Windows);
        "Work Description" := TempBlob.Blob;
        MODIFY;
    end;

    [Scope('Personalization')]
    procedure GetWorkDescription() : Text;
    var
        TempBlob : Record "99008535" temporary;
        CR : Text[1];
    begin
        CALCFIELDS("Work Description");
        IF NOT "Work Description".HASVALUE THEN
          EXIT('');
        CR[1] := 10;
        TempBlob.Blob := "Work Description";
        EXIT(TempBlob.ReadAsText(CR,TEXTENCODING::Windows));
    end;

    local procedure LookupContact(CustomerNo : Code[20];ContactNo : Code[20];var Contact : Record "5050");
    var
        ContactBusinessRelation : Record "5054";
    begin
        IF ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer,CustomerNo) THEN
          Contact.SETRANGE("Company No.",ContactBusinessRelation."Contact No.")
        ELSE
          Contact.SETRANGE("Company No.",'');
        IF ContactNo <> '' THEN
          IF Contact.GET(ContactNo) THEN ;
    end;

    procedure SetAllowSelectNoSeries();
    begin
        SelectNoSeriesAllowed := TRUE;
    end;

    local procedure SetDefaultSalesperson();
    var
        UserSetup : Record "91";
    begin
        IF NOT UserSetup.GET(USERID) THEN
          EXIT;

        IF UserSetup."Salespers./Purch. Code" <> '' THEN
          VALIDATE("Salesperson Code",UserSetup."Salespers./Purch. Code");
    end;

    procedure SelltoCustomerNoOnAfterValidate(var SalesHeader : Record "36";var xSalesHeader : Record "36");
    begin
        IF SalesHeader.GETFILTER("Sell-to Customer No.") = xSalesHeader."Sell-to Customer No." THEN
          IF SalesHeader."Sell-to Customer No." <> xSalesHeader."Sell-to Customer No." THEN
            SalesHeader.SETRANGE("Sell-to Customer No.");
    end;

    procedure SelectSalesHeaderCustomerTemplate() : Code[10];
    var
        CustomerTemplate : Record "5105";
        Contact : Record "5050";
    begin
        Contact.GET("Sell-to Contact No.");
        IF (Contact.Type = Contact.Type::Person) AND (Contact."Company No." <> '')THEN
          Contact.GET(Contact."Company No.");
        IF NOT Contact.ContactToCustBusinessRelationExist THEN
          IF CONFIRM(SelectCustomerTemplateQst,FALSE) THEN BEGIN
            COMMIT;
            IF PAGE.RUNMODAL(0,CustomerTemplate) = ACTION::LookupOK THEN
              EXIT(CustomerTemplate.Code);
          END;
    end;

    local procedure ModifyBillToCustomerAddress();
    var
        Customer : Record "18";
    begin
        IF IsCreditDocType THEN
          EXIT;
        IF ("Bill-to Customer No." <> "Sell-to Customer No.") AND Customer.GET("Bill-to Customer No.") THEN
          IF HasBillToAddress AND HasDifferentBillToAddress(Customer) THEN
            ShowModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId,
              ModifyCustomerAddressNotificationLbl,ModifyCustomerAddressNotificationMsg,
              UpdateAddressWithBilltoAddressTok,"Bill-to Customer No.","Bill-to Name",FIELDNAME("Bill-to Customer No."));
    end;

    local procedure ModifyCustomerAddress();
    var
        Customer : Record "18";
    begin
        IF IsCreditDocType THEN
          EXIT;
        IF Customer.GET("Sell-to Customer No.") AND HasSellToAddress AND HasDifferentSellToAddress(Customer) THEN
          ShowModifyAddressNotification(GetModifyCustomerAddressNotificationId,
            ModifyCustomerAddressNotificationLbl,ModifyCustomerAddressNotificationMsg,
            UpdateAddressWithSellToAddressFunctionTok,"Sell-to Customer No.","Sell-to Customer Name",FIELDNAME("Sell-to Customer No."));
    end;

    local procedure ShowModifyAddressNotification(NotificationID : Guid;NotificationLbl : Text;NotificationMsg : Text;NotificationFunctionTok : Text;CustomerNumber : Code[20];CustomerName : Text[50];CustomerNumberFieldName : Text);
    var
        MyNotifications : Record "1518";
        NotificationLifecycleMgt : Codeunit "1511";
        ModifyCustomerAddressNotification : Notification;
    begin
        IF NOT MyNotifications.IsEnabled(NotificationID) THEN
          EXIT;

        ModifyCustomerAddressNotification.ID := NotificationID;
        ModifyCustomerAddressNotification.MESSAGE := STRSUBSTNO(NotificationMsg,CustomerName);
        ModifyCustomerAddressNotification.ADDACTION(NotificationLbl,CODEUNIT::"Document Notifications",NotificationFunctionTok);
        ModifyCustomerAddressNotification.ADDACTION(DontShowAgainActionLbl,CODEUNIT::"Document Notifications",DontShowAgainFunctionTok);
        ModifyCustomerAddressNotification.SCOPE := NOTIFICATIONSCOPE::LocalScope;
        ModifyCustomerAddressNotification.SETDATA(FIELDNAME("Document Type"),FORMAT("Document Type"));
        ModifyCustomerAddressNotification.SETDATA(FIELDNAME("No."),"No.");
        ModifyCustomerAddressNotification.SETDATA(CustomerNumberFieldName,CustomerNumber);
        NotificationLifecycleMgt.SendNotification(ModifyCustomerAddressNotification,RECORDID);
    end;

    procedure RecallModifyAddressNotification(NotificationID : Guid);
    var
        MyNotifications : Record "1518";
        ModifyCustomerAddressNotification : Notification;
    begin
        IF IsCreditDocType OR (NOT MyNotifications.IsEnabled(NotificationID)) THEN
          EXIT;

        ModifyCustomerAddressNotification.ID := NotificationID;
        ModifyCustomerAddressNotification.RECALL;
    end;

    procedure GetModifyCustomerAddressNotificationId() : Guid;
    begin
        EXIT('509FD112-31EC-4CDC-AEBF-19B8FEBA526F');
    end;

    procedure GetModifyBillToCustomerAddressNotificationId() : Guid;
    begin
        EXIT('2096CE78-6A74-48DB-BC9A-CD5C21504FC1');
    end;

    procedure SetModifyCustomerAddressNotificationDefaultState();
    var
        MyNotifications : Record "1518";
    begin
        MyNotifications.InsertDefault(GetModifyCustomerAddressNotificationId,
          ModifySellToCustomerAddressNotificationNameTxt,ModifySellToCustomerAddressNotificationDescriptionTxt,TRUE);
    end;

    procedure SetModifyBillToCustomerAddressNotificationDefaultState();
    var
        MyNotifications : Record "1518";
    begin
        MyNotifications.InsertDefault(GetModifyBillToCustomerAddressNotificationId,
          ModifyBillToCustomerAddressNotificationNameTxt,ModifyBillToCustomerAddressNotificationDescriptionTxt,TRUE);
    end;

    procedure DontNotifyCurrentUserAgain(NotificationID : Guid);
    var
        MyNotifications : Record "1518";
    begin
        IF NOT MyNotifications.Disable(NotificationID) THEN
          CASE NotificationID OF
            GetModifyCustomerAddressNotificationId:
              MyNotifications.InsertDefault(NotificationID,ModifySellToCustomerAddressNotificationNameTxt,
                ModifySellToCustomerAddressNotificationDescriptionTxt,FALSE);
            GetModifyBillToCustomerAddressNotificationId:
              MyNotifications.InsertDefault(NotificationID,ModifyBillToCustomerAddressNotificationNameTxt,
                ModifyBillToCustomerAddressNotificationDescriptionTxt,FALSE);
          END;
    end;

    local procedure HasDifferentSellToAddress(Customer : Record "18") : Boolean;
    begin
        EXIT(("Sell-to Address" <> Customer.Address) OR
          ("Sell-to Address 2" <> Customer."Address 2") OR
          ("Sell-to City" <> Customer.City) OR
          ("Sell-to Country/Region Code" <> Customer."Country/Region Code") OR
          ("Sell-to County" <> Customer.County) OR
          ("Sell-to Post Code" <> Customer."Post Code") OR
          ("Sell-to Contact" <> Customer.Contact));
    end;

    local procedure HasDifferentBillToAddress(Customer : Record "18") : Boolean;
    begin
        EXIT(("Bill-to Address" <> Customer.Address) OR
          ("Bill-to Address 2" <> Customer."Address 2") OR
          ("Bill-to City" <> Customer.City) OR
          ("Bill-to Country/Region Code" <> Customer."Country/Region Code") OR
          ("Bill-to County" <> Customer.County) OR
          ("Bill-to Post Code" <> Customer."Post Code") OR
          ("Bill-to Contact" <> Customer.Contact));
    end;

    [Scope('Personalization')]
    procedure ShowInteractionLogEntries();
    var
        InteractionLogEntry : Record "5065";
    begin
        IF "Bill-to Contact No." <> '' THEN
          InteractionLogEntry.SETRANGE("Contact No.","Bill-to Contact No.");
        CASE "Document Type" OF
          "Document Type"::Order:
            InteractionLogEntry.SETRANGE("Document Type",InteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
          "Document Type"::Quote:
            InteractionLogEntry.SETRANGE("Document Type",InteractionLogEntry."Document Type"::"Sales Qte.");
        END;

        InteractionLogEntry.SETRANGE("Document No.","No.");
        PAGE.RUN(PAGE::"Interaction Log Entries",InteractionLogEntry);
    end;

    [Scope('Personalization')]
    procedure GetBillToNo() : Code[20];
    begin
        IF ("Document Type" = "Document Type"::Quote) AND
           ("Bill-to Customer No." = '') AND ("Bill-to Contact No." <> '') AND
           ("Bill-to Customer Template Code" <> '')
        THEN
          EXIT("Bill-to Contact No.");
        EXIT("Bill-to Customer No.");
    end;

    [Scope('Personalization')]
    procedure GetCurrencySymbol() : Text[10];
    var
        GeneralLedgerSetup : Record "98";
        Currency : Record "4";
    begin
        IF GeneralLedgerSetup.GET THEN
          IF ("Currency Code" = '') OR ("Currency Code" = GeneralLedgerSetup."LCY Code") THEN
            EXIT(GeneralLedgerSetup.GetCurrencySymbol);

        IF Currency.GET("Currency Code") THEN
          EXIT(Currency.GetCurrencySymbol);

        EXIT("Currency Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var SalesHeader : Record "36");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNoSeries(var SalesHeader : Record "36");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var SalesHeader : Record "36");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var SalesHeader : Record "36");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineByChangedFieldName(SalesHeader : Record "36";var SalesLine : Record "37";ChangedFieldName : Text[100]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var SalesHeader : Record "36";FieldNo : Integer;TableID : array [10] of Integer;No : array [10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLine(var SalesLine : Record "37";var TempSalesLine : Record "37" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteAccepted(var SalesHeader : Record "36");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendSalesHeader(var SalesHeader : Record "36";ShowDialog : Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFieldsBilltoCustomer(var SalesHeader : Record "36";Customer : Record "18");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForSalesLineRecreation(var SalesLine : Record "37");
    begin
    end;
}

