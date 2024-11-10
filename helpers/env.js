
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

class Env{

    constructor(){
        
    }

    loadFileLog(envFile){
        envFile = fs.realpathSync(envFile);
        if(this.getBoolean('DEBUG')==true || this.get('DEBUG')==''){
            console.log('\n=============================================');
            console.log('Loaded env file:', envFile);
            console.log('=============================================\n');
        }
    }

    loadEnvFile(envFile){
        if(envFile){
            envFile = path.join(envFile);
            const dotenvConfig = dotenv.config({ path: envFile });
            if (dotenvConfig.error) {
                throw dotenvConfig.error;
            }
            this.loadFileLog(envFile);
        }else{
            this.loadDefaultEnv();
        }
        return this;
    }

    loadDefaultEnv(){
        var defaultDotEnv = path.join('../', '.env');
        if(!fs.existsSync(defaultDotEnv)){
            defaultDotEnv = path.join('./', '.env');
        }
        // if(fs.existsSync(defaultDotEnv)){
            const dotenvConfig = dotenv.config({ path: defaultDotEnv });
            if (dotenvConfig.error) {
                throw dotenvConfig.error
            }
            this.loadFileLog(defaultDotEnv);
        // }
    }
    
    get(name) {
        return process.env[name] ? process.env[name] : '';
    }

    getInt(name) {
        return parseInt(process.env[name]);
    }

    getBoolean(name){
        return (String(process.env[name]).toLowerCase() === 'true');
    }

    getJon(name) {
        return JSON.parse(process.env[name]);
    }

    toArray(envName){
        var string = this.get(envName);
        var array = string.split(',').map(function(item) {
            return item.trim();
        });
        return array;
    }

}

module.exports = new Env();