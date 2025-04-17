def call(){
    withCredentials([string(credentialsId: 'AI_PULL_SECRET', variable: 'FILE')]) {
        sh 'set +x; echo  $FILE > $PULL_SECRET_FILE'
    }
}
