##############################
#.SYNOPSIS
# Get list of all Email Templates used against all "Active" BPMs
#
#.DESCRIPTION
# Will provide a list of the Email Templates, which node, stage and BPM they are used in
#
#.EXAMPLE
# $results = Get-HB-BPMEmailTemplates
#
##############################
function Get-HB-BPMEmailTemplates
{

    #===================================================================
    #   Sets the colours of the progress bar
    #===================================================================
    $Host.PrivateData.ProgressBackgroundColor = 'Yellow' 
    $Host.PrivateData.ProgressForegroundColor = 'Black'

    #===================================================================
    #   Clear any Hornbill Parameters in the cache
    #===================================================================
    Clear-HB-Params

    #===================================================================
    #   Invoke the API to get a list of all the BPM Workflows, then
    #   only return the ones that are "Active"
    #===================================================================
    $bpm_ActiveWorkflows = (Invoke-HB-XMLMC "bpm" "workflowList").params.workflow | where-object "active" -eq $true

    #===================================================================
    #   Define variables
    #===================================================================

        # Count of "Active" BPM Workflows
        $activeBPMCount = $bpm_ActiveWorkflows.count

        # Set the starting loop number to 0 (for the progress bar)
        $currentBPMCount = 0

        # Define the array to hold the objects that will be return to the user
        # after the function is run
        $newList = @()

    #===================================================================
    #   Loop through each "Active" BPM
    #===================================================================
    foreach($bpm in $bpm_ActiveWorkflows) 
    {

        #===================================================================
        #   Set the Progress Bar percentage
        #===================================================================
        $progressPercent = ($currentBPMCount / $activeBPMCount) * 100

        #===================================================================
        #   Display the progress bar percentage
        #===================================================================
        write-progress "Extracting nodes from Business Process Management Workflows in Hornbill [$currentBPMCount out of $activeBPMCount]" -PercentComplete $progressPercent

        #===================================================================
        #   Clear any Hornbill Parameters in the cache
        #===================================================================
        Clear-HB-Params

        #===================================================================
        #   Define the parameters to return the details of the BPM Workflows
        #   using the name of the current BPM in the loop
        #===================================================================
        Add-HB-Param    "application"   "com.hornbill.servicemanager"
        Add-HB-Param    "name"        $bpm.name`

        #===================================================================
        #   Invoke the API to return the BPM details
        #===================================================================
        $bpm_SelectedWorkflow = Invoke-HB-XMLMC "bpm" "workflowGet"

        #===================================================================
        #   Get all the stages of the current BPM
        #===================================================================
        $bpm_All_Stages = $bpm_SelectedWorkflow.Params.definition.stage

        #===================================================================
        #   Display the progress bar percentage
        #===================================================================
        foreach($bpm_stage in $bpm_All_Stages)
        {

            #===================================================================
            #   Get the name of the current stage in the loop
            #===================================================================
            $bpm_stageName = $bpm_stage.displayName

            #===================================================================
            #   Get the flowcode nodes from the current stage
            #===================================================================
            $bpm_stageNodes = $bpm_stage.flow.node

            #===================================================================
            #   Loop through each node in the flowcode nodes of the current stage
            #===================================================================
            foreach($node in $bpm_stageNodes)
            {

                #===================================================================
                #   Conver the node metadata to JSON
                #   - replace any text that says "value_MM" to "value_MONTH" because
                #     JSON doesn't like there to be duplicate values, and "value_mm"
                #     already exists.
                #===================================================================
                $nodeJSON = ($node.nodeMetaData.replace("value_MM","value_MONTH")) | convertfrom-json

                #===================================================================
                #   If there is no metadata, then skip this iteration
                #===================================================================
                if(-not $nodeJSON.flowcodePath) { continue } 

                #===================================================================
                #   If the flowcode path contains "notifyEmailCustomer" then this is
                #   a node that will hold our Email Template ID
                #===================================================================
                if($nodeJSON.flowcodePath.Contains("notifyEmailCustomer"))
                {

                    #===================================================================
                    #   Retrieve the Input Parameters of the node
                    #===================================================================
                    $nodeInputParams = $nodeJSON.inputparams

                    #===================================================================
                    #   Loop through each Input Parameter from the node
                    #===================================================================
                    foreach($inputParam in $nodeInputParams)
                    {

                        #===================================================================
                        #   If the Input Parameter is called "emailTemplate"
                        #===================================================================
                        if($inputParam.name -eq "emailTemplate")
                        {

                            #===================================================================
                            #   Retrieve the details of the BPM, the stage, the node and the value
                            #   of the Template ID
                            #===================================================================
                            $value_BPM = $bpm.title
                            $value_Stage = $bpm_stageName
                            $value_Node = $node.displayName
                            $value_Template = $inputParam.value

                            #===================================================================
                            #   Combine the details into an Object
                            #===================================================================
                            $PSCustomObject = [PSCustomObject]@{
                                BPM             = $value_BPM
                                Stage           = $value_Stage
                                Node            = $value_Node
                                EmailTemplate   = $value_Template
                            }

                            #===================================================================
                            #   Add the object to the array
                            #===================================================================
                            $newList += $PSCustomObject
                        }
                    }
                }
            }
        }

        #===================================================================
        #   Increase the iteration in the loop (for the progress bar)
        #===================================================================
        $currentBPMCount++

    }

    #===================================================================
    #   Count the number of items in the array
    #===================================================================
    $itemCount = $newList.count

    #===================================================================
    #   Create an object used for the output the function
    #===================================================================
    $resultObject = [PSCustomObject]@{
        status = "Success"
        rowDataCount = $itemCount
        rowData = $newList
    }

    #===================================================================
    #   Return the Output of the function to the user
    #===================================================================
   return $resultObject | format-list

}

if (get-command Get-HB-BPMEmailTemplates) {
    write-host "[Function] Get-HB-BPMEmailTemplates loaded succesfully..." -ForegroundColor Green
}