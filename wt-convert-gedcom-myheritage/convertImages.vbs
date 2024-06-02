

txtfile = ".\..\OurFamilyTree_fromWikitree.ged"
newfile = "OurFamilyTree_fromWikitree.ged"

Dim objStream, strData
Set objStream = CreateObject("ADODB.Stream")
objStream.CharSet = "utf-8"
objStream.Open
objStream.LoadFromFile(txtfile)
strData = objStream.ReadText()
objStream.Close

dim arrText
arrText = Split(strData, vbLf)


For i = 0 To UBound(arrText) - 1
    strLine = arrText(i)
    If InStr(strLine," FILE http") > 2 Then
        strline = "2" & mid(strline,InStr(strLine," FILE http"))
		
		'add format type (needed for MyHeritage)
		strformat = "jpg" 'Right(strLine,3)
		
		strline = "2 FORM Image" & vbLf & strline
		strline = strline & vbLf & "2 FORM " & strformat
		'strline = strline & vbLf & "2 FORM jpg" 
		strline = strline & vbLf & "2 _PRIM Y" 
    End If
	
	
	'concat middle name to name (condition if Name and followed by middle name)
    If InStr(strLine,"2 GIVN") * InStr(arrText(i+1),"2 _MIDN") > 0 Then
		strline = strline & arrText(i+1)
		arrText(i+1) = ""
    End If
	
	'replace middle name tag if any
    If InStr(strLine,"2 _MIDN") > 0 Then
		strline = Replace(strline,"2 _MIDN", vbBack)
    End If
	
	strNewText = strNewText & strLine & vbLf

Next


Dim objStreamWrite
Set objStreamWrite = CreateObject("ADODB.Stream")
objStreamWrite.CharSet = "utf-8"
objStreamWrite.Open
objStreamWrite.WriteText strNewText
objStreamWrite.SaveToFile newfile, 2
objStreamWrite.Close


msgbox "Completed"