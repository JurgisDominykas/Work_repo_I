#!usr/bin/perl

use strict;
use warnings;
use utf8;

use CGI;

use Kernel::System::Web::Request;

use Data::Dumper;

use vars (qw($Self));

my $FieldTreeObject = $Kernel::OM->Get('Kernel::System::FieldTree');

my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

$Helper->FixedTimeSet();

{
    $Helper->BeginWork();

    my $ClassList = $FieldTreeObject->ClassList();

    $Self->True(
        $ClassList,
        'ClassList()',
    );


    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
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

    my $ClassListAltered = $FieldTreeObject->ClassList();

    push @{ $ClassList }, '_Testing_Class';

    $Self->IsDeeply(
        $ClassList,
        $ClassListAltered,
        'ClassList()'
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ClassList = $FieldTreeObject->ClassList();

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ClassRename = $FieldTreeObject->ClassRename(
        ClassOld => '_Testing_Class',
        ClassNew => '_Testing_Class_New',
    );

    $Self->True(
        $ClassRename,
        'ClassRename()',
    );

    push @{ $ClassList }, '_Testing_Class_New';

    my $ClassListAltered = $FieldTreeObject->ClassList();

    $Self->IsDeeply(
        $ClassList,
        $ClassListAltered,
        'ClassRename()',
    );

    $ClassRename = $FieldTreeObject->ClassRename(
        ClassOld => '_Testing_Class_New',
        ClassNew => '_Testing_Class',
    );
    
    $Helper->Rollback();
}

{   
    $Helper->BeginWork();

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my @ItemIDs;

    $ItemIDs[0] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemID,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[1] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemID,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemList = $FieldTreeObject->ItemList(
        Class       => '_Testing_Class',
        ParentID    => $ItemID,
    );

    $Self->True(
        $ItemList,
        'ItemList()',
    );

    my $ItemListTest = {
        $ItemIDs[0] => 'Testing_Class_BBB',
        $ItemIDs[1] => 'Testing_Class_AAA',
    };

    $Self->IsDeeply(
        $ItemList,
        $ItemListTest,
        'ItemList()'
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my @ItemIDs;

    $ItemIDs[0] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
        Position        => 2,
    );

    $ItemIDs[1] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemIDs[0],
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
        Position        => 1,
    );

    $ItemIDs[2] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAAA',
        FriendlyName    => 'Friendly_Testing_Class_AAAA',
        ParentID        => $ItemIDs[0],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
        Position        => 0,
    );

    my $ItemList = $FieldTreeObject->ItemListSorted(
        Class       => '_Testing_Class',
    );

    $Self->True(
        $ItemList,
        'ItemListSorted()',
    );

    my $ItemListTest = {
        $ItemIDs[2] => 'Testing_Class_AAAA',
        $ItemIDs[1] => 'Testing_Class_BBB',
        $ItemIDs[0] => 'Testing_Class',
    };

    $Self->IsDeeply(
        $ItemList,
        $ItemListTest,
        'ItemListSorted()'
    );

    $Helper->Rollback();
}

{   
    $Helper->BeginWork();

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $Item = $FieldTreeObject->ItemGet(
        ItemID => $ItemID,
    );
    
    $Self->True(
        $Item,
        'ItemGet()',
    );

    $Self->Is(
        $Item->{ItemID},
        $ItemID,
        'ItemGet()',
    );
    
    $Self->Is(
        $Item->{Class},
        '_Testing_Class',
        'ItemGet()',
    );
    
    $Self->Is(
        $Item->{Name},
        'Testing_Class',
        'ItemGet()'
    );
        
    $Self->Is(
        $Item->{FriendlyName},
        'Friendly_Testing_Class',
        'ItemGet()',
    );
        
    $Self->Is(
        $Item->{ParentID},
        -1,
        'ItemGet()',
    );
        
    $Self->Is(
        $Item->{ValidID},
        1,
        'ItemGet()',
    );

    $Self->Is(
        $Item->{Comment},
        'Test Comment',
        'ItemGet()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my @ItemIDs;

    $ItemIDs[0] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[1] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_B',
        FriendlyName    => 'Friendly_Testing_Class_B',
        ParentID        => $ItemIDs[0],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[2] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_C',
        FriendlyName    => 'Friendly_Testing_Class_C',
        ParentID        => $ItemIDs[1],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my  $Result = $FieldTreeObject->FieldTreesRecursiveIDs(
        ItemID      => $ItemIDs[2],
        Separator   => ", ",
    );

    $Self->True(
        $Result,
        'FieldTreesRecursiveIDs()',
    );

    $Self->Is(
        $Result,
        join(", ", @ItemIDs[1,2]),
        'FieldTreesRecursiveIDs() Probobly Is Wrong!',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my @ItemIDs;

    $ItemIDs[0] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[1] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_B',
        FriendlyName    => 'Friendly_Testing_Class_B',
        ParentID        => $ItemIDs[0],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[2] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_C',
        FriendlyName    => 'Friendly_Testing_Class_C',
        ParentID        => $ItemIDs[1],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );
    
    my $Result = $FieldTreeObject->ItemRecursiveName(
        ItemID => $ItemIDs[2],
    );

    $Self->True(
        $Result,
        'ItemRecursiveName()',
    );

    $Self->Is(
        $Result,
        'Testing_Class_B - Testing_Class_C',
        'ItemRecursiveName()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();
    
    my @ItemIDs;

    $ItemIDs[0] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_A',
        FriendlyName    => 'Friendly_Testing_Class_A',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[1] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_B',
        FriendlyName    => 'Friendly_Testing_Class_B',
        ParentID        => $ItemIDs[0],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    $ItemIDs[2] = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_C',
        FriendlyName    => 'Friendly_Testing_Class_C',
        ParentID        => $ItemIDs[1],
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );
    
    my $Result = $FieldTreeObject->ItemRecursiveNamesHash(
        ItemID => $ItemIDs[2],  
    );

    $Self->True(
        $Result,
        'ItemRecursiveNamesHash()',
    );

    my $ResultTest = {
        Label2 => 'Testing_Class_C',
        Label1 => 'Testing_Class_B',
    };

    $Self->IsDeeply(
        $Result,
        $ResultTest,
        'ItemRecursiveNamesHash()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();
    
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
    
    my $Update = $FieldTreeObject->ItemUpdate(
        ItemID          => $ItemID,
        Name            => 'Testing_C_A',
        FriendlyName    => 'Friendly_Testing_C_A',
        ParentID        =>  2,
        ValidID         =>  1,
        CssClass        => 'Test',
        Comment         => 'Comment',
        UserID          => 1,
    );

    $Self->True(
        $Update,
        'ItemUpdate()',
    );

    $Update = $FieldTreeObject->ItemGet(
        ItemID          => $ItemID,
    );

    $Self->Is(
        $Update->{ItemID},
        $ItemID,
        'ItemUpdate()',
    );

    $Self->Is(
        $Update->{Name},
        'Testing_C_A',
        'ItemUpdate()',
    );

    $Self->Is(
        $Update->{FriendlyName},
        'Friendly_Testing_C_A',
        'ItemUpdate()',
    );


    $Self->Is(
        $Update->{ParentID},
        2,
        'ItemUpdate()',
    );


    $Self->Is(
        $Update->{ValidID},
        1,
        'ItemUpdate()',
    );


    $Self->Is(
        $Update->{CssClass},
        'Test',
        'ItemUpdate()',
    );


    $Self->Is(
        $Update->{Comment},
        'Comment',
        'ItemUpdate()',
    );


    $Self->Is(
        $Update->{CreateBy},
        1,
        'ItemUpdate()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    $Self->True(
        $FieldID,
        'FieldAdd()',
    );

    my $Fields = $FieldTreeObject->FieldGet(
        FieldID => $FieldID,
    );

    $Self->True(
        $Fields,
        'FieldGet()',
    );

    $Self->Is(
        $Fields->{FieldID},
        $FieldID,
        'FieldGet()',
    );

    $Self->Is(
        $Fields->{FieldType},
        'Text',
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Name},
        'Test_Field',
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{FriendlyName},
        'Friendly_Test_Field',
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Required},
        1,
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Template},
        'Test',
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Target},
        16,
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Position},
        2,
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{ValidID},
        1,
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Hidden},
        0,
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{Comment},
        'Test comment',
        'FieldGet()',
    );


    $Self->Is(
        $Fields->{CreateBy},
        1,
        'FieldGet()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $FieldsHash = $FieldTreeObject->FieldList(
        FieldTreeID     => $ItemID,
    );

    $Self->True(
        $FieldsHash,
        'FieldList()',
    );
    
    my $FieldsHashTest = {
        $FieldID => "Test_Field_2",
    };

    $Self->IsDeeply(
        $FieldsHash,
        $FieldsHashTest,
        'FieldList()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Update = $FieldTreeObject->FieldUpdate(
        FieldID         => $FieldID,
        FieldType       => 'Boolean',
        Name            => 'Test_F',
        FriendlyName    => 'Friendly_Test_F',
        Required        => 0,
        Template        => 'Test_T',
        Target          => 15,
        Position        => 3,
        ValidID         => 1,
        Hidden          => 1,
        Comment         => 'Comment',
        UserID          => 1,
    );

    $Self->True(
        $Update,
        'FieldUpdate()',
    );

    my $Fields = $FieldTreeObject->FieldGet(
        FieldID         => $FieldID,
    );
    
    $Self->Is(
        $Fields->{FieldID},
        $FieldID,
        'FieldUpdate()'
    );
                                                
    $Self->Is(
        $Fields->{FieldType},
        'Boolean',
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Name},
        'Test_F',
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{FriendlyName},
        'Friendly_Test_F',
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Required},
        0,
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Template},
        'Test_T',
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Target},
        15,
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Position},
        3,
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{ValidID},
        1,
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Hidden},
        1,
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{Comment},
        'Comment',
        'FieldUpdate()'
    );


    $Self->Is(
        $Fields->{CreateBy},
        1,
        'FieldUpdate()'
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Fields = $FieldTreeObject->FieldList(
        FieldTreeID => $ItemID,
    );

    my $Result = $FieldTreeObject->ValueSetAdd(
        Data => {$FieldID => 'Test value',},
    );

    $Self->True(
        $Result,
        'ValueSetAdd()',
    );

    $Self->Is(
        $Result->{'HistoryLines'}[0],
        '%%Test_Field%%Test value',
        'ValueSetAdd()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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


    my $GetFieldsValueConfig = {
        CGIParam => {
            'DynamicField_Test_Field_' . $FieldID => 'Test value',
        },
    };

    my $WebRequest = CGI->new( $GetFieldsValueConfig->{CGIParam} );

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Config = (
        ParamObject => $LocalParamObject,
        FieldTreeID => $ItemID,
        Prefix      => 'DynamicField_Test',
    );

    my $Result = $FieldTreeObject->GetFieldsValues(%Config);

    $Self->True(
        $Result,
        'GetFieldsValues()',
    );

    $Self->IsDeeply(
        $Result,
        {$FieldID => 'Test value'},
        'GetFieldsValues()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Result = $FieldTreeObject->ValueSetGet(
        ValueSetID  => $ValueSetAddRes->{ValueSetID},
    );

    $Self->True(
        $Result,
        'ValueSetGet()',
    );

    $Self->Is(
        $Result->{$FieldID},
        'Test value',
        'ValueSetGet()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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


    my $Result = $FieldTreeObject->ValueSetUpdate(
        ValueSetID  => $ValueSetAddRes->{ValueSetID},
        Data        => {$FieldID => 'New test data',},
    );

    $Self->True(
        $Result,
        'ValueSetUpdate',
    );

    my $ValueSetGetRes = $FieldTreeObject->ValueSetGet(
        ValueSetID  => $ValueSetAddRes->{ValueSetID},
    );

    $Self->Is(
        $ValueSetGetRes->{$FieldID},
        'New test data',
        'ValueSetUpadate()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Config= {
        CGIParam => {
            'DynamicField_Test' . $FieldID => 'Test value',
        },
    };

    my $WebRequest = CGI->new( $Config->{CGIParam} );

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Config = (
        ParamObject     => $LocalParamObject,
        FieldTreeID     => $ItemID,
        Prefix          => 'DynamicField_Test',
        OnlyReturnData  => 1,
    );

    my $Result = $FieldTreeObject->ValueSetFromPOST(%Config);

    $Self->True(
        $Result,
        'ValueSetFromPOST()',
    );

    $Self->Is(
        $Result->{$FieldID},
        'Test value',
        'ValueSetFromPOST()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Data = $FieldTreeObject->ValueSetGetFieldTreeID(
        ValueSetID => $ValueSetAddRes->{ValueSetID},
    );

    $Self->True(
        $Data,
        'ValueSetGetFieldTreeID()',
    );

    $Self->Is(
        $Data,
        $ItemID,
        'ValueSetGetFieldTreeID()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Result = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID => 'Test value'},
    );

    $Self->True(
        $Result,
        'TreeValueSetAdd()',
    );

    $Self->IsDeeply(
        $Result->{HistoryLines},
        ['%%Problem Source%%' . $ItemID.','],
        'TreeValueSetAdd() Test is not final!',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Config= {
        CGIParam => {
            'DynamicField_Test' . $ItemID => 'Test value',
        },
    };

    my $WebRequest = CGI->new( $Config->{CGIParam} );

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Config = (
        ParamObject     => $LocalParamObject,
        Class           => '_Testing_Class',
        Prefix          => 'DynamicField_Test',
        ValueSetID      => 'NEW',
    );

    my $Result = $FieldTreeObject->TreeValueSetFromPOST(%Config);
    
    $Self->True(
        $Result,
        'TreeValueSetFromPOST()',
    );

    $Self->Is(
        $Result->{HistoryLines}->[0],
        '%%Problem Source%%' . $ItemID . ',',
        'TreeValueSetFromPOST() Test is not final!',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $Config= {
        CGIParam => {
            'DynamicField_Test' . $ItemID => 'Test value',
        },
    };

    my $WebRequest = CGI->new( $Config->{CGIParam} );

    my $LocalParamObject = Kernel::System::Web::Request->new(
        WebRequest => $WebRequest,
    );

    my %Config = (
        ParamObject     => $LocalParamObject,
        Class           => '_Testing_Class',
        Prefix          => 'DynamicField_Test',
        ValueSetID      => 'NEW',
    );

    my $TreeValuePOSTRes = $FieldTreeObject->TreeValueSetFromPOST(%Config);

    my $Result = $FieldTreeObject->TreeValueSetUpdate(
        ValueSetID  => $TreeValuePOSTRes->{ValueSetID},
        Data        => {$ItemID => 0},
    );

    $Self->True(
        $Result,
        'TreeValueSetUpdate() Test is not final!',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $TreeValueAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID => 'Test value'},
    );

    my $Result = $FieldTreeObject->RulesPostProcess(
        ValueSetID => $TreeValueAddRes->{ValueSetID},
    );

    $Self->True(
        $Result,
        'RulesPostProcess()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $TreeValueSetAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID => '1'},
    );

    my $Result = $FieldTreeObject->TreeValueSetGet(
        ValueSetID => $TreeValueSetAddRes->{ValueSetID},
    );

    $Self->True(
        $Result,
        'TreeValueSetGet()',
    );

    $Self->Is(
        $Result->{$ItemID},
        1,
        'TreeValueSetGet() Test is not finished!'
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $TreeValueSetAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID => '1'},
    );

    my $Result = $FieldTreeObject->OpenedItemsList(
        ValueSetID => $TreeValueSetAddRes->{ValueSetID},
    );

    $Self->True(
        $Result,
        'OpenedItemsList()',
    );

    $Self->Is( 
        $Result->{$ItemID},
        1,
        'OpenedItemsList() ?????',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $TreeValueSetAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID => '1'},
    );

    my $Result = $FieldTreeObject->TreeOpenedItemsList(
        ValueSetID => $TreeValueSetAddRes->{ValueSetID},
    );

    $Self->True(
        $Result,
        'TreeOpenedItemsList()',
    );

    $Self->Is( 
        $Result->{$ItemID},
        1,
        'TreeOpenedItemsList() ?????',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemIDp1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemIDp2= $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemIDp1,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemIDc = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemIDp2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $Result = $FieldTreeObject->ItemParentsList(
        ItemID => $ItemIDc, 

    );

    $Self->True(
        $Result,
        'ItemParentsList()',
    );

    $Self->IsDeeply(
        $Result,
        [$ItemIDp1, $ItemIDp2, $ItemIDc,],
        'ItemParentsList()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemIDp = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemIDc1= $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemIDp,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemIDc2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemIDc1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $Result = $FieldTreeObject->ChildItemList(
        ItemID => $ItemIDp, 
    );

    $Self->True(
        $Result,
        'ChildItemList()',
    );

    $Self->IsDeeply(
        $Result,
        [$ItemIDp, $ItemIDc1, $ItemIDc2,],
        'ChildItemList()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemID1,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $Result  = $FieldTreeObject->_JSONInternal(
        Class   => '_Testing_Class',
        ItemID  => $ItemID1,
    );

    $Self->True(
        $Result,
        '_JSONInternal()',
    );

    my $Test = [
        {
            acceptdrop      => 'false',
            canhavechildren => 'true',
            id              => $ItemID2,
            txt             => 'Testing_Class_BBB',
            items           => [
                {
                    acceptdrop      => 'false',
                    canhavechildren => '',
                    id              => $ItemID3,
                    txt             => 'Testing_Class_AAA',
                    items           => [],
                },
            ],
        },
    ];

    $Self->IsDeeply(
        $Result,
        $Test,
        '_JSONInternal()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemID1,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID2,
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

    my $TreeValueSetAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID2 => '1'},
    );


    my $JSON = $FieldTreeObject->_JSONInternal(
        Class   => '_Testing_Class',
        ItemID  => $ItemID1,
    );

    my @Result = $FieldTreeObject->JSON(
        ValueSetID => $TreeValueSetAddRes->{ValueSetID},
        Class   => '_Testing_Class',
    );

    $Self->True(
        @Result,
        'JSON()',
    );

    my $Test = [
        {
            open            => 'true',
            checkbox        => '',
            acceptdrop      => 'false',
            canhavechildren => 'true',
            id              => $ItemID2,
            txt             => 'Testing_Class_BBB',
            items           => [
                {
                    open            => '',
                    checkbox        => 'true',
                    acceptdrop      => 'false',
                    canhavechildren => '',
                    id              => $ItemID3,
                    txt             => 'Testing_Class_AAA',
                    items           => [], 
                },
            ],
        },
    ];

    $Self->IsDeeply(
        \@Result,
        $Test,
        'JSON()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

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

    my $FieldID1 = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field_A',
        FriendlyName    => 'Friendly_Test_Field_A',
        Required        =>  1,
        Template        => 'Test',
        Target          => '16',
        Position        => '2',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetAddResT = $FieldTreeObject->ValueSetAdd(
        Data => {$FieldID1 => 'Test value',},
    );

    my $FieldID2 = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID,
        FieldType       => 'Text',
        Name            => 'Test_Field_B',
        FriendlyName    => 'Friendly_Test_Field_B',
        Required        =>  1,
        Template        => 'Test',
        Target          => '16',
        Position        => '1',
        ValidID         => 1,
        Hidden          => 0,
        Comment         => 'Test comment',
        UserID          => 1,
    );

    my $ValueSetAddResS = $FieldTreeObject->ValueSetAdd(
        Data => {$FieldID2 => 'Copy value',},
    );

    my $Result = $FieldTreeObject->ValueSetCopy(
        SourceValueSetID    => $ValueSetAddResS->{ValueSetID},
        TargetValueSetID    => $ValueSetAddResT->{ValueSetID},
        UserID              => 1,
    );

    $Self->True(
        $Result,
        'ValueSetCopy()',
    );

    my $ValueSetGetT = $FieldTreeObject->ValueSetGet(
        ValueSetID  => $ValueSetAddResT->{ValueSetID},
    );

    $Self->IsDeeply(
        $ValueSetGetT,
        { $FieldID2 => 'Copy value',},
        'ValueSetCopy()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemID1,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID2,
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

    my $TreeValueSetAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID2 => '1'},
    );


    my $JSON = $FieldTreeObject->_JSONInternal(
        Class   => '_Testing_Class',
        ItemID  => $ItemID1,
    );

    my @Result = $FieldTreeObject->TreeJSON(
        Class   => '_Testing_Class',
    );

    $Self->True(
        @Result,
        'TreeJSON()',
    );

    my $Test = [
        {
            open            => '',
            checkbox        => '',
            acceptdrop      => 'false',
            canhavechildren => 'true',
            id              => $ItemID2,
            txt             => 'Testing_Class_BBB',
            items           => [
                {
                    open            => '',
                    checkbox        => 'true',
                    acceptdrop      => 'false',
                    canhavechildren => '',
                    id              => $ItemID3,
                    txt             => 'Testing_Class_AAA',
                    items           => [], 
                },
            ],
        },
    ];

    $Self->IsDeeply(
        \@Result,
        $Test,
        'TreeJSON()',
    );

    $Helper->Rollback();
}

{
    $Helper->BeginWork();

    my $ItemID1 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class',
        FriendlyName    => 'Friendly_Testing_Class',
        ParentID        => -1,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID2 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_BBB',
        FriendlyName    => 'Friendly_Testing_Class_BBB',
        ParentID        => $ItemID1,
        ValidID         => 1, #FIND OUT HOW "VALID" WORKS !!!
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $ItemID3 = $FieldTreeObject->ItemAdd(
        Class           => '_Testing_Class',
        Name            => 'Testing_Class_AAA',
        FriendlyName    => 'Friendly_Testing_Class_AAA',
        ParentID        => $ItemID2,
        ValidID         => 1,
        CssClass        => '',
        Comment         => 'Test Comment',
        UserID          => 1,
    );

    my $FieldID = $FieldTreeObject->FieldAdd(
        FieldTreeID     => $ItemID2,
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

    my $TreeValueSetAddRes = $FieldTreeObject->TreeValueSetAdd(
        Class => '_Testing_Class',
        Data  => {$ItemID2 => '1'},
    );


    my $JSON = $FieldTreeObject->_JSONInternal(
        Class   => '_Testing_Class',
        ItemID  => $ItemID1,
    );

    my $Result = $FieldTreeObject->TreeAsSelection (
        Class       => '_Testing_Class',
        Name        => 'Test_name',
        ValueSetID  => $TreeValueSetAddRes->{ValueSetID},
    );

    $Self->True(
        $Result,
        'TreeAsSelection()',
    );

    my $Test = qq^<select name="Test_name" id="Test_name" >\n^
    .qq^<option value="">--</option>\n^
    .qq^<optgroup label="Testing_Class_BBB"></optgroup>\n^
    .qq^<option value="$ItemID3" >&nbsp;&nbsp;&nbsp;&nbsp;Testing_Class_AAA</option>\n^
    .qq^</select>\n^;

    $Self->Is(
        $Result,
        $Test,
        'TreeAsSelection()',
    );

    $Helper->Rollback();
}

$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

1;
