# Depends on OSD REady Check Script (Step in TS)
# Execute Tasksequence Step needs Condition with TS Variable -> CanDeploy -eq 'True' if False it will not run the TS

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$Models="Virtual Machine",
"ThinkPad Yoga 460",
"ThinkPad P50",
"ThinkPad T460s",
"ThinkPad T450s",
"ThinkPad Yoga 370",
"ThinkPad X1 Yoga 1st",
"ThinkPad X1 Carbon 6th",
"ThinkPad E14 Gen 3",
"ThinkCentre M720q",
"ThinkPad T480s",
"ThinkPad W541",
"ThinkStation P300",
"CF-54-3",
"ThinkPad W541",
"HP EliteBook 840 G3",
"HP EliteBook 840 G4",
"HP EliteBook 840 G5",
"HP EliteBook x360 1030 G2",
"HP EliteBook x360 1030 G3",
"HP EliteDesk 800 G2 SFF",
"HP Z240 Tower Workstation",
"HP EliteDesk 800 G3 DM 65W",
"HP EliteDesk 800 G3 SFF",
"HP Z230 Tower Workstation",
"HP ZBook 15 G2",
"HP ZBook 15 G3",
"HP ZBook 15 G4",
"HP ZBook 15 G5",
"HP Z220 CMT Workstation",
"HP EliteDesk 800 G4 DM 65W",
"HP EliteBook 840 G6",
"HP EliteDesk 800 G4 SFF",
"HP EliteBook x360 1040 G6",
"HP EliteDesk 800 G5 Desktop Mini",
"HP EliteBook 850 G4",
"HP EliteDesk 800 G5 TWR",
"HP EliteDesk 800 G5 SFF",
"HP EliteBook 840 G7 Notebook PC",
"HP ProBook 650 G5",
"HP EliteDesk 800 G6 Small Form Factor PC",
"HP ZBook Fury 15 G7 Mobile Workstation",
"FZ55-1",
"HP EliteBook 845 G7 Notebook PC",
"HP EliteBook 845 G8 Notebook PC",
"HP EliteDesk 800 G2 DM 65W",
"HP Elitebook x360 1040 G8 Notebook PC",
"HP Z2 Mini G5 Workstation",
"HP EliteDesk 800 G6 Desktop Mini PC",
"HP EliteDesk 800 G8 Small Form Factor PC",
"HP EliteDesk 800 G8 Tower PC",
"HP EliteBook 840 G8 Notebook PC",
"HP Z2 Tower G5 Workstation",
'HP EliteBook 850 G8 Notebook PC',
"HP ZBook Fury 15.6 inch G8 Mobile Workstation PC"


if($tsenv.Value('IsAC') -eq 'TRUE'-and $tsenv.Value('TotalRam') -eq 'TRUE' -and $tsenv.Value('Model') -iin $Models -and $tsenv.Value('_SMSTSBootUEFI') -eq 'TRUE') {
		$SupportedModel = 'TRUE'
		$CanDeploy = 'True'
		$tsenv.Value('SupportedModel') = $SupportedModel
		$tsenv.Value('CanDeploy') = $CanDeploy
	} 
	Else {
		if($tsenv.Value('Model') -iin $Models) {$SupportedModel = 'TRUE'; $tsenv.Value('SupportedModel') = $SupportedModel} Else {$SupportedModel = 'FALSE'; $tsenv.Value('SupportedModel') = $SupportedModel}
		$CanDeploy = 'False'; $tsenv.Value('CanDeploy') = $CanDeploy
	}