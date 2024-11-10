

const fs = require('fs');
const path = require('path');
const networkName = hre.network.name;
class Data{

    dataFile = path.join(__dirname, '../data/'+networkName+'_data.json');
    jsonData = {};

    constructor(){
        this._loadFile();
    }

    _loadFile(){
        if(fs.existsSync(this.dataFile)){
            try{
                var data = fs.readFileSync(this.dataFile, "utf-8");
                this.jsonData = JSON.parse(data);
            }catch(error){
                console.log(error);
            }
        }
    }

    saveFile(){
        try{
            fs.writeFileSync(this.dataFile, JSON.stringify(this.jsonData, null, 2));
        }catch(error){
            console.log(error);
        }
    }

    get(key){
        return this.jsonData[key];
    }

    set(key, value){
        this.jsonData[key] = value;
        this.saveFile();
    }

    push(key, value){
        if(!this.jsonData[key]){
            this.jsonData[key] = [];
        }
        this.jsonData[key].push(value);
        this.saveFile();
    }

    pushToMemory(key, value){// not save file
        if(!this.jsonData[key]){
            this.jsonData[key] = [];
        }
        this.jsonData[key].push(value);
    }

}

module.exports = new Data();