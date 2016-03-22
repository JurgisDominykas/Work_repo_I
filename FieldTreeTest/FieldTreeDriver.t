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

	my $FieldID	= $FieldTreeObject->FieldAdd(
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

	for (keys %{$DynamicFieldsConfig}) {
		warn $_;
	};

	$Helper->Rollback();
}

$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

1;
