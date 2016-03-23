#!usr/bin/perl

use strict;
use warnings;
use utf8;

use CGI;

use Kernel::System::Web::Request;

use Data::Dumper;

use vars (qw($Self));

my $FieldTreeObject = $Kernel::OM->Get('Kernel::System::FieldTree');
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DriverObject = $Kernel::OM->Get('Kernel::System::DynamicField::Driver::FieldTree');
my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

$Helper->FixedTimeSet();

{
	$Helper->BeginWork();

	my $TicketID = $TicketObject->TicketCreate (
		Title 			=> 'Some Ticket Title',
		Queue 			=> 'Raw',
		Lock 			=> 'unlock',
		Priority		=> '3 normal',
		State			=> 'new',
		CustomerID		=> '123456',
		CustomerUser 	=> 'customer@examle.com',
		OwnerID			=> 1,
		UserID			=> 1,
	);

	$Self->True(
		$TicketID,
		'TicketCreate()'
	);

	my $ItemID = $FieldTreeObject->ItemAdd(
		Class			=> '_Testing_Class',
		Name			=> 'Testing_Class_A',
		FriendlyName	=> 'Friendly_Testing_Class_A',
		ParentID		=> -1,
		ValidID			=> 1,
		CssClass		=> '',
		Comment			=> 'Test Comment',
		UserID			=> 1,
	);

	$Self->True(
		$ItemID,
		'ItemAdd()',
	);

	my $FieldID = $FieldTreeObject->FieldAdd(
		FieldTreeID 	=> $ItemID,
		FieldType		=> 'Text',
		Name			=> 'Test_Field',
		FriendlyName	=> 'Friendly_Test_Name',
		Required		=> 1,
		Template		=> 'Test',
		Target			=> '16',
		Position		=> '2',
		ValidID			=> 1,
		Hidden 			=> 0,
		Comment			=> 'Test comment',
		UserID			=> 1,
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
		Title 			=> 'Some Ticket Title',
		Queue 			=> 'Raw',
		Lock 			=> 'unlock',
		Priority		=> '3 normal',
		State			=> 'new',
		CustomerID		=> '123456',
		CustomerUser 	=> 'customer@examle.com',
		OwnerID			=> 1,
		UserID			=> 1,
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
		Class			=> '_Testing_Class',
		Name			=> 'Testing_Class_A',
		FriendlyName	=> 'Friendly_Testing_Class_A',
		ParentID		=> -1,
		ValidID			=> 1,
		CssClass		=> '',
		Comment			=> 'Test Comment',
		UserID			=> 1,
	);

	my $FieldID = $FieldTreeObject->FieldAdd(
		FieldTreeID 	=> $ItemID,
		FieldType		=> 'Text',
		Name			=> 'Test_Field',
		FriendlyName	=> 'Friendly_Test_Name',
		Required		=> 1,
		Template		=> 'Test',
		Target			=> '16',
		Position		=> '2',
		ValidID			=> 1,
		Hidden 			=> 0,
		Comment			=> 'Test comment',
		UserID			=> 1,
	);

	my $ValueSetRes = $DriverObject->ValueSet(
		Value => {
			ValueSetID		=> "NEW",
			FieldsValues	=> {
				$FieldID => "Test text",
			},
		},
		DynamicFieldConfig	=> {
			ID => $DynamicFieldID,
			ObjectType => "FieldTree",
		},
		ObjectID			=> $TicketID,
		UserID				=> 1,
	);

	$Self->True(
		$ValueSetRes,
		"ValueSet()",
	);
	$Helper->Rollback();
}

$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

1;
