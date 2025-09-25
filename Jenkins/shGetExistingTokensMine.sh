pipeline {
    agent { label 'localhost' }
    
    environment {
        GIT_URL = 'https://x-token-auth:ATCTT3xFfGN05moRIKpKHRQE8nKie6Tcmg7XQZxplLAAUQHLTBqueQS2vsnrD2nNwx10qH0P1KHsvu6wPp_pAtlz2C0J0RCefAe8aWGAg-sKJ42n44czrWHRuASJyXyKPqmZlUGFaU7GerQsCqZLC2WXkBItVgjj-wG2_mmK6RrLKlZc9gSNGck=E337A7F7@bitbucket.org/dhs-kolea/kolea-automation-suite.git'
        //OFFICE365_QA_VALIDATION_WEBHOOK_URL = 'https://prod-113.westus.logic.azure.com:443/workflows/1b7d3c288c0a47a1b9c7a1924d82c039/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=4OUS-LLnrw6FWCz3CXyrBu5MR6cyYyoz6a2kcbbeA_o'
    }
    
    stages {
        stage('Initialize') {
            steps {
                echo "Pipeline started with build number ${env.BUILD_NUMBER}"
                //bat 'taskkill /F /IM chromedriver.exe /T 2>nul || exit 0'
            }
        }
        stage('Clone Repository') {
                when {
                    expression {"${params.GitPull}" == 'Yes' }
                }
                steps {
                    script {
                        def bName = "${params['Branch Name']}"
                        bName = bName.replace(",", "")
                        env.branchName = bName
                    }
                    echo "Cloning the repository with branch ${env.branchName} .."
                    git(
                        url: "${env.GIT_URL}",
                        branch: "${env.branchName}"
                        )
                    echo "Building Test suite package..."+params.Environment
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        script {
                            def status
                            dir('.') {
                               status = bat(returnStatus: true, script: "mvn clean package -DskipTests=true")
                            }
                            if (status == 0) {
                                echo params.Environment+" Test suite package created successfully."
                                powershell """
                                md -Force -Path ../../kolea-automation-suite
                                cp ./target/kolea-automation-suite*.zip ../../kolea-automation-suite
                                Expand-Archive -Path ../../kolea-automation-suite/kolea-automation-suite*.zip -DestinationPath ../../kolea-automation-suite -Force
                                """
                            } else {
                                echo params.Environment+" Test suite package creation FAILED"
                                error "************  ${params.Environment} Test suite package creation FAILED. **************"
                            }
                        }
                    }
                }
        }

        stage('Run Smoke Test') {
            steps {
                echo "Running Smoke Test in: "+params.Environment
                sleep(time: 5, unit: 'SECONDS')
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        def status
                        dir('../../kolea-automation-suite') {
                          echo "Running... "
                          sleep(time: 5, unit: 'SECONDS')
                          status = bat(returnStatus: true, script: "java -Denv=${params.Environment} -Dbuild.number=${env.BUILD_NUMBER} -jar kolea-automation-suite-0.0.1.jar suites/kolea-nonprd-smoke-test.xml -usedefaultlisteners false")
                        }
                        echo "**Status: "+status
                        if (status == 0 || status == 2) {
                            echo params.Environment+" Smoke Test Result: PASSED"
                        } else {
                            echo params.Environment+" Smoke Test Result: FAILED"
                            error "************  ${params.Environment} Smoke test FAILED. **************"
                        }
                    }
                }
            }
        }
        
        stage('Send Report via Email') {
            steps {
                script {
                    echo "**currentBuild.currentResult: "+currentBuild.currentResult
                    echo 'Sending Report via Email...'
                     dir('../../kolea-automation-suite/reports') {
                        def archiveName = "TestAutomationReport-${env.BUILD_NUMBER}"
                        def files = findFiles(glob: "TestAutomationReport*-${env.BUILD_NUMBER}.html.png")
                        def reportImagebase64 = readFile(file: files[0].name, encoding: 'Base64')
                        powershell """
                        Compress-Archive -Path TestAutomationReport*-"${env.BUILD_NUMBER}".html -DestinationPath "${archiveName}" -Force
                        """
                        powershell """
                        Remove-Item -Path TestAutomationReport*-"${env.BUILD_NUMBER}".html -Force -ErrorAction SilentlyContinue
                        """
                        def emailSubject = currentBuild.currentResult == 'SUCCESS' ? "${env.Environment} - ${env.JOB_NAME} - ${currentBuild.currentResult}":"${env.Environment} - ${env.JOB_NAME} - ${currentBuild.currentResult} - ACTION REQUIRED !!!"
                        def sendLogFlag = currentBuild.currentResult == 'SUCCESS' ? false:true
                        def emailBody = """
                            <p>Hi Team,</p>
                            <p>Please find below the kolea-smoke-test results.</p>
                            <img src="data:image/png;base64,${reportImagebase64}" alt="Report Image">
                            <br>
                            Build URL: <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a>
                            <p>Smoke Test reports are attached.</p>
                            <p>Regards,<br/>KOLEA Automation</p>
                            """
                        emailext (
                            subject: emailSubject,
                            body: emailBody,
                            to: env.SMOKE_TEST_RECIPIENTS,
                            mimeType: 'text/html',
                            attachmentsPattern: "TestAutomationReport*-${env.BUILD_NUMBER}.zip",
                            attachLog: sendLogFlag,
                            compressLog: sendLogFlag
                        )
                    }
                }
            }
        }
        
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
            bat 'taskkill /F /IM chromedriver.exe /T 2>nul || exit 0'
            office365ConnectorSend webhookUrl: "${env.OFFICE365_QA_VALIDATION_WEBHOOK_URL}",
                    status: 'SUCCESS',
                    color: '008000',
                    message: "The KOLEA Smoke Test Suite has been successfully executed in **${params.Environment}**",
                    adaptiveCards: true,
                    factDefinitions: [[name: "Build Duration", template: "${currentBuild.durationString}"]]
        }
        
        failure {
            echo 'Pipeline failed.'
            bat 'taskkill /F /IM chromedriver.exe /T 2>nul || exit 0'
            office365ConnectorSend webhookUrl: "${env.OFFICE365_QA_VALIDATION_WEBHOOK_URL}",
                message: "The KOLEA Smoke Test Suite failed in **${params.Environment}**", 
                status: 'FAILED',
                color: 'FF0000',
                adaptiveCards: true,
                factDefinitions: [[name: "Build Duration", template: "${currentBuild.durationString}"]]
        }
    }
}