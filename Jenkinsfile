pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh "docker run --rm -v /docker/gogs/jenkins/home'${env.WORKSPACE.substring(17,env.WORKSPACE.length())}':'/root' cutec/buildhost-lazarus-x64 bash /root/build.sh submodules"
            } 
        }
        stage ("Build") {
            steps {
                parallel (
                    "Windows" : {
                        sh "docker run --rm -v /docker/gogs/jenkins/home'${env.WORKSPACE.substring(17,env.WORKSPACE.length())}':'/root/promet' cutec/buildhost-lazarus-windows bash z:/root/promet/build.sh all"
                    },
                    "Linux-x64" : {
                        sh "docker run --rm -v /docker/gogs/jenkins/home'${env.WORKSPACE.substring(17,env.WORKSPACE.length())}':'/root' cutec/buildhost-lazarus-x64  bash /root/build.sh"
                    },
                    "Linux-x86" : {
                        sh "docker run --rm -v /docker/gogs/jenkins/home'${env.WORKSPACE.substring(17,env.WORKSPACE.length())}':'/root' cutec/buildhost-lazarus-i386 bash /root/build.sh"
                    },
                    "Linux-armhf" : {
                        catchError {
                            sh "docker run --rm -v /docker/gogs/jenkins/home'${env.WORKSPACE.substring(17,env.WORKSPACE.length())}':'/root' -v /usr/bin/qemu-arm-static:/usr/bin/qemu-arm-static  cutec/buildhost-lazarus-armhf bash /root/build.sh server"
                            sh "set +e"
                        } 
                        sh "set +e"
                        echo currentBuild.result
                    }
                )
            }    
        }    
        stage('Upload') {
            steps {
                //sh "cd /docker/gogs/jenkins/home'${env.WORKSPACE.substring(17,env.WORKSPACE.length())}'"
                catchError {
                    dir(env.WORKSPACE) {
                        sh "bash /promet/setup/upload_builds.sh"
                        sh "set +e"
                    }
                }    
                currentBuild.result = 'SUCCESS'
                sh "set +e"
                echo currentBuild.result
            }
        }
    }
    post {
        always {
            sh 'rm -rf promet/output/*/*.compiled'    
            sh 'rm -rf promet/output/*/*.dbg'    
            sh 'rm -rf promet/output/*/*/*.compiled'
            sh 'rm -rf promet/output/*/*/*.dbg'
            sh 'rm -rf promet/output/*/*/*.o'
            sh 'rm -rf promet/output/*/*/*.ppu'
            sh 'rm -rf promet/output/*/*/*.a'
            archiveArtifacts artifacts: "promet/output/", fingerprint: true
        }
        failure {
            //cleanWs()
            mail to: 'jenkins@chris.ullihome.de',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                 <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>"""
        }       
    }
}
