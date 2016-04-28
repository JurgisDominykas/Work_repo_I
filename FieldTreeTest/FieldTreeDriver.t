#!usr/bin/perl

use strict;
use warnings;
use utf8;

use CGI;

use Kernel::System::Web::Request;

use Kernel::Output::HTML::Layout;

use Data::Dumper;

use vars (qw($Self));

my $FieldTreeObject = $Kernel::OM->Get('Kernel::System::FieldTree');
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DriverObject = $Kernel::OM->Get('Kernel::System::DynamicField::Driver::FieldTree');
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
my $TimeObject      = $Kernel::OM->Get('Kernel::System::Time');
my $LayoutObject = Kernel::Output::HTML::Layout->new(
    Lang         => 'en',
    UserTimeZone => '+0',
);

$Helper->FixedTimeSet();

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    $Self->True(
        $TicketID,
        'TicketCreate()'
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $Self->True(
        $ItemID,
        'ItemAdd()',
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    $Self->True(
        $FieldID,
        'FieldAdd()',
    );

    my $DynamicFieldsConfig = $ConfigObject->Get('DynamicFields::Driver');

    $Self->Is(
        ref $DynamicFieldsConfig,
        'HASH',
        'Dynamic Field configuration',
    );

    $Self->IsNotDeeply(
        $DynamicFieldsConfig,
        {},
        'Dynamic field configuration is not empty',
    );

    $Self->Is(
        ref $DriverObject,
        'Kernel::System::DynamicField::Driver::FieldTree',
        'DriverObject is loaded',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetRes = $DriverObject->ValueSet(
        Value => {
            ValueSetID      => "NEW",
            FieldsValues    => {
                $FieldID => "Test text",
            },
        },
        DynamicFieldConfig  => {
            ID => $DynamicFieldID,
            ObjectType => "FieldTree",
        },
        ObjectID            => $TicketID,
        UserID              => 1,
    );

    $Self->True(
        $ValueSetRes,
        "ValueSet()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetRes = $DriverObject->ValueSet(
        Value => {
            ValueSetID      => "NEW",
            FieldsValues    => {
                $FieldID => "Test text",
            },
        },
        DynamicFieldConfig  => {
            ID => $DynamicFieldID,
            ObjectType => "FieldTree",
        },
        ObjectID            => $TicketID,
        UserID              => 1,
    );

    my $ValueGetRes = $DriverObject->ValueGet(
       DynamicFieldConfig => {
            ID => $DynamicFieldID,
       },
       ObjectID            => $TicketID,
    );

    $Self->True(
        $ValueGetRes,
        "ValueGet()",
    );

    $Self->Is(
        ref $ValueGetRes,
        "HASH",
        "ValueGet()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetRes = $DriverObject->ValueSet(
        Value => {
            ValueSetID      => "NEW",
            FieldsValues    => {
                $FieldID => "Test text",
            },
        },
        DynamicFieldConfig  => {
            ID => $DynamicFieldID,
            ObjectType => "FieldTree",
        },
        ObjectID            => $TicketID,
        UserID              => 1,
    );

    my $ValueDeleteRes = $DriverObject->ValueDelete(
        DynamicFieldConfig => {
            ID => $DynamicFieldID,
        },
        ObjectID           => $TicketID,
        UserID             => 1,
    );

    $Self->True(
        $ValueDeleteRes,
        "ValueDelete()",
    );

    my $ValueGetRes = $DriverObject->ValueGet(
       DynamicFieldConfig => {
            ID => $DynamicFieldID,
       },
       ObjectID           => $TicketID,
    );

    $Self->False(
        $ValueGetRes,
        "ValueDelete()",
    );
    $Helper->Rollback();
};

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetRes = $DriverObject->ValueSet(
        Value => {
            ValueSetID      => "NEW",
            FieldsValues    => {
                $FieldID => "Test text",
            },
        },
        DynamicFieldConfig  => {
            ID => $DynamicFieldID,
            ObjectType => "FieldTree",
        },
        ObjectID            => $TicketID,
        UserID              => 1,
    );

    my $ValueDeleteRes = $DriverObject->AllValuesDelete(
        DynamicFieldConfig => {
            ID => $DynamicFieldID,
        },
        UserID             => 1,
    );

    $Self->True(
        $ValueDeleteRes,
        "AllValuesDelete()",
    );

    my $ValueGetRes = $DriverObject->ValueGet(
       DynamicFieldConfig => {
            ID => $DynamicFieldID,
       },
       ObjectID           => $TicketID,
    );

    $Self->False(
        $ValueGetRes,
        "AllValuesDelete()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $GetFieldsValueConfig = {
        CGIParam => {
            'DynamicField_FieldTree_FieldTreeID' => "123",
        },
    };

    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Test = (
        DynamicFieldConfig => {
            ID            => 123,
            InternalField => 0,
            Name          => 'FieldTree',
            Label         => 'FieldTree',
            LabelEscaped  => 'FieldTree',
            FieldOrder    => 123,
            FieldType     => 'FieldTree',
            ObjectType    => 'Ticket',
            Config        => {
                DefaultValue => 'Default',
                Link         => '',
            },
            ValidID    => 1,
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
        },
        LayoutObject    => $LayoutObject,
        ParamObject     => $LocalParamObject,
        Class           => 'TestClass',
        UseDefaultValue => 0,
        Mandatory       => 1,
    );

    my $FieldHTML = $DriverObject->EditFieldRender( %Test );

    $Self->Is(
        ref $FieldHTML,
        "HASH",
        "EditFieldRender()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetRes = $DriverObject->ValueSet(
        Value => {
            ValueSetID      => "NEW",
            FieldsValues    => {
                $FieldID => "Test text",
            },
        },
        DynamicFieldConfig  => {
            ID => $DynamicFieldID,
            ObjectType => "FieldTree",
        },
        ObjectID            => $TicketID,
        UserID              => 1,
    );


    my $GetFieldsValueConfig = {
        CGIParam => {
            'DynamicField_FieldTree_FieldTreeID' => $ItemID,
            'DynamicField_FieldTree_Field_'.$FieldID => 1,
            DynamicField_FieldTree => "Test",
        },
    };


    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Test = (
        DynamicFieldConfig => {
            ID            => 123,
            InternalField => 0,
            Name          => 'FieldTree',
            Label         => 'FieldTree',
            LabelEscaped  => 'FieldTree',
            FieldOrder    => 123,
            FieldType     => 'FieldTree',
            ObjectType    => 'Ticket',
            Config        => {
                DefaultValue => 'Default',
                Link         => '',
            },
            ValidID    => 1,
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
        },
        LayoutObject    => $LayoutObject,
        ParamObject     => $LocalParamObject,
        Class           => 'TestClass',
        UseDefaultValue => 0,
        Mandatory       => 1,
    );

    my $Value = $DriverObject->EditFieldValueGet( %Test );

    my $Test = {
        FieldsValues => {
            $FieldID => 1,
        },
        ValueSetID  => "Test",
    };

    $Self->IsDeeply(
        $Value,
        $Test,
        "EditFieldValueGet()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetRes = $DriverObject->ValueSet(
        Value => {
            ValueSetID      => "NEW",
            FieldsValues    => {
                $FieldID => "Test text",
            },
        },
        DynamicFieldConfig  => {
            ID => $DynamicFieldID,
            ObjectType => "FieldTree",
        },
        ObjectID            => $TicketID,
        UserID              => 1,
    );


    my $GetFieldsValueConfig = {
        CGIParam => {
            'DynamicField_FieldTree_FieldTreeID' => $ItemID,
            'DynamicField_FieldTree_Field_'.$FieldID => 1,
            DynamicField_FieldTree => "Test",
        },
    };


    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Test = (
        DynamicFieldConfig => {
            ID            => 123,
            InternalField => 0,
            Name          => 'FieldTree',
            Label         => 'FieldTree',
            LabelEscaped  => 'FieldTree',
            FieldOrder    => 123,
            FieldType     => 'FieldTree',
            ObjectType    => 'Ticket',
            Config        => {
                DefaultValue => 'Default',
                Link         => '',
            },
            ValidID    => 1,
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
        },
        LayoutObject    => $LayoutObject,
        ParamObject     => $LocalParamObject,
        Class           => 'TestClass',
        UseDefaultValue => 0,
        Mandatory       => 1,
    );

    my $Value = $DriverObject->EditFieldValueValidate( %Test );

    my $Test = {
        ErrorMessage    => undef,
        ServerError     => undef,
    };

    $Self->IsDeeply(
        $Value,
        $Test,
        "EditFieldValueValidate()",
    );


    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $GetFieldsValueConfig = {
        CGIParam => {
            'DynamicField_FieldTree_FieldTreeID' => "123",
        },
    };

    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Test = (
        DynamicFieldConfig => {
            ID            => 123,
            InternalField => 0,
            Name          => 'FieldTree',
            Label         => 'FieldTree',
            LabelEscaped  => 'FieldTree',
            FieldOrder    => 123,
            FieldType     => 'FieldTree',
            ObjectType    => 'Ticket',
            Config        => {
                DefaultValue => 'Default',
                Link         => '',
            },
            ValidID    => 1,
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
        },
        LayoutObject    => $LayoutObject,
        ParamObject     => $LocalParamObject,
        Class           => 'TestClass',
        UseDefaultValue => 0,
        Mandatory       => 1,
    );

    my $Value = $DriverObject->DisplayValueRender( %Test );

    $Self->Is(
        ref $Value,
        "HASH",
        "DisplayValueRender()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $GetFieldsValueConfig = {
        CGIParam => {
            'DynamicField_FieldTree_FieldTreeID' => "123",
        },
    };

    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Test = (
        DynamicFieldConfig => {
            ID            => 123,
            InternalField => 0,
            Name          => 'FieldTree',
            Label         => 'FieldTree',
            LabelEscaped  => 'FieldTree',
            FieldOrder    => 123,
            FieldType     => 'FieldTree',
            ObjectType    => 'Ticket',
            Config        => {
                DefaultValue => 'Default',
                Link         => '',
            },
            ValidID    => 1,
            CreateTime => '2011-02-08 15:08:00',
            ChangeTime => '2011-06-11 17:22:00',
        },
        LayoutObject    => $LayoutObject,
        ParamObject     => $LocalParamObject,
        Class           => 'TestClass',
        UseDefaultValue => 0,
        Mandatory       => 1,
    );

    my $Result = $DriverObject->SearchFieldRender(%Test);

    $Self->Is(
        ref $Result,
        'HASH',
        "SearchFieldRender()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $Result = $DriverObject->IsSortable();

    $Self->False(
        $Result,
        'IsSortable()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my %Test = (
        DynamicFieldConfig => {
            Name => "FieldTree",
        },
        ParamObject => undef,
    );

    my $Param = 'Search_DynamicField_' . "$Test{DynamicFieldConfig}->{Name}";

    my $GetFieldsValueConfig = {
        CGIParam => {
            "$Param" => "123",
        },
    };

    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    $Test{ParamObject} = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );


    my $Result = $DriverObject->SearchFieldValueGet(%Test);

    $Self->Is(
        $Result,
        "123",
        "SearchFieldValueGet()",
    );

    $Helper->Rollback();
};

{
    $Helper->BeginWork();

    my %Test = (
        DynamicFieldConfig => {
            Name => "FieldTree",
        },
        ParamObject => undef,
    );

    my $Param = 'Search_DynamicField_' . "$Test{DynamicFieldConfig}->{Name}";

    my $GetFieldsValueConfig = {
        CGIParam => {
            "$Param" => "123",
        },
    };

    my $WebRequest = CGI->new($GetFieldsValueConfig->{CGIParam});

    $Test{ParamObject} = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my $Result = $DriverObject->SearchFieldParameterBuild(%Test);

    my $Expected = {
        Display     => "123",
        Parameter   => {
            Like    => "*123*",
        },
    };

    $Self->IsDeeply(
        $Result,
        $Expected,
        "SearchFieldParameterBuild()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_B',
        FriendlyName    => 'Friendly_Testing_Class_B',
        ParentID        => $ItemID1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_C',
        FriendlyName    => 'Friendly_Testing_Class_C',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $Result = $DriverObject->_FieldTree(
        Class => '_Testing_Class'
    );

    my $Expected = {
        $ItemID1 => '',
        $ItemID2 => 'Testing_Class_B',
        $ItemID3 => 'Testing_Class_B - Testing_Class_C',
    };

    $Self->IsDeeply(
        $Result,
        $Expected,
        "_FieldTree()",
    );

    $Result = $DriverObject->_SortedFieldTree(
        Class => '_Testing_Class',
    );

    $Expected = [
        $ItemID1, $ItemID2, $ItemID3
    ];

    $Self->IsDeeply(
        $Result,
        $Expected,
        "_SortedFieldTree()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

     my %Test = (
        DynamicFieldConfig => {
            Name => "FieldTree",
            Label => "FieldTree",
        },
    );

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => 'ProblemType',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => 'ProblemType',
        Name            => 'Testing_Class_B',
        FriendlyName    => 'Friendly_Testing_Class_B',
        ParentID        => $ItemID1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => 'ProblemType',
        Name            => 'Testing_Class_C',
        FriendlyName    => 'Friendly_Testing_Class_C',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $Expected = {
        Values  => {
            $ItemID1 => '',
            $ItemID2 => 'Testing_Class_B',
            $ItemID3 => 'Testing_Class_B - Testing_Class_C',
        },
        Element => 'DynamicField_FieldTree',
        Name    => 'FieldTree',
    };

    my $Result = $DriverObject->StatsFieldParameterBuild(%Test);

    $Self->IsDeeply(
        $Result,
        $Expected,
        "StatsFieldParameterBuild()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $Result = $DriverObject->CommonSearchFieldParameterBuild(
        Value => "Test",
    );

    $Self->IsDeeply(
        $Result,
        {Equals => "Test",},
        "CommonSearchFieldParameterBuild()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => $ItemID1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_C',
        FriendlyName    => 'Friendly_Testing_Class_C',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID3,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Field',
        Required        =>  1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetAddRes = $FieldTreeObject->ValueSetAdd(
        Data => {$FieldID => 'Test value',},
    );

    my %Test = (
        Value =>{ ValueSetID => $ValueSetAddRes->{ValueSetID},},
    );

    my $Result = $DriverObject->ReadableValueRender(%Test);

    my $Expected = {
        Value           => "Pasirinkta kategorija: Testing_Class_C<br /> <br />Friendly_Test_Field: Test value<br /><br /> <br />",
        Title           => "TITLE",
        FieldTreeName   => "Testing_Class_C",
    };

    $Self->IsDeeply(
        $Result,
        $Expected,
        "ReadableValueRender()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my %Test = (
        DynamicFieldConfig => {
            Name => "FieldTree",
        },
    );

    my $Result = $DriverObject->TemplateValueTypeGet(%Test);

    my $Expected = {
        DynamicField_FieldTree          => "SCALAR",
        Search_DynamicField_FieldTree   => "SCALAR",
    };

    $Self->IsDeeply(
        $Result,
        $Expected,
        "TemplateValueTypeGet()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $Result = $DriverObject->IsAJAXUpdateable();

    $Self->False(
        $Result,
        "IsAJAXUpdateabe()",
    );

    $Helper->Rollback();
};

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );


    $Self->True(
        0,
        "RandomValueSet() Needs work",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $Result = $DriverObject->IsMatchable();

    $Self->True(
        $Result,
        "IsMatchable()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $Result = $DriverObject->AJAXPossibleValuesGet();

    $Self->False(
        $Result,
        "ALAXPossibleValuesGet()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my %Test = (
        DynamicFieldConfig => {
            Name => "FieldTree",
        },
        ObjectAttributes => {
            DynamicField_FieldTree => "Test",
        },
        Value => "Test",
    );

    my $Result = $DriverObject->ObjectMatch(%Test);

    $Self->True(
        $Result,
        "ObjectMatch()",
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $TicketID = $TicketObject->TicketCreate (
        Title           => 'Some Ticket Title',
        Queue           => 'Raw',
        Lock            => 'unlock',
        Priority        => '3 normal',
        State           => 'new',
        CustomerID      => '123456',
        CustomerUser    => 'customer@examle.com',
        OwnerID         => 1,
        UserID          => 1,
    );

    my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => "dynamicfieldtest",
        Label      => 'a description',
        FieldOrder => 9991,
        FieldType  => 'FieldTree',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => 'a value',
        },
        ValidID => 1,
        UserID  => 1,
    );

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

     my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field',
        FriendlyName    => 'Friendly_Test_Name',
        Required        => 1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $Result = $DriverObject->HistoricalValuesGet(
        DynamicFieldConfig => {
            ID => $DynamicFieldID,
        },
    );

    $Self->True(
        0,
        "HistoricalValuesGet() Need work",
    );

    $Helper->Rollback();
}

$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

1;
