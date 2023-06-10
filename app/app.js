let express = require("express"); //подключение модуля express(улучшенный http модуль)
let bodyParser = require('body-parser');
let mod = require('./dbModule');    //подключение dbModule - пользовательский модуль работы с БД
let dateFormat = require('dateformat'); //подключение модуля для работы с датами
let fs = require('fs');
let stream = require('stream');

let app = express();

const parkId = '8118EE92-FC78-4F74-8245-3C7C7B1170EC';//ключ парковки - после добавления парковки, взять из БД

app.use(express.static(__dirname + "/public"));
app.use(bodyParser.urlencoded({extended:false}));
app.use(bodyParser.json());

app.listen(3000, function(){//Запуск сервера на 3000 порту
    console.log("Сервер ожидает подключения...");
});

app.post("/login", function(req, res) {//запрос проверки при входе в аккаунт
    let login = req.body.login,
        password = req.body.password,
        type;
    if(login.indexOf('@') == -1){//узнаём вход происходит по email или номеру телефона
        type = 'phone';
    } else {
        type = 'email';
    }
    console.log(type);
    console.log(req.body);
    mod.LogInValidation(login,password,type).then(function (result) {//вызов функции проверки
        if(result.errorCode == 0){//код ошибки:0 означает что ошибок нет(пользовательское решение)
            res.send([{errorCode: 0, user: result}]); //отправка ответа клиенту
        } else {
            res.send([{errorCode: 1, errorMessage: "Неверные данные"}]); //отправка ответа клиенту с ошибкой
        }
    })
});

app.post("/registration", function(req, res){//проверка при регистрации на уникальность мейла и телефона
    let phoneCount = +0, // счётчик телефонов в БД если 1 то ошибка
        emailCount = +0; // счётчик email в БД
    mod.registrationValidationEmail(req.body.email).then(function (resultE) { // вызов функции проверки email
        emailCount = resultE; // присваиваем результат проверки
        mod.registrationValidationPhone(req.body.number).then(function (resultL) { // вызов функции проверки телефона
            phoneCount = resultL; // присваиваем результат проверки
            if(phoneCount == 0 && emailCount == 0) { // смотрим если совпадений найдено не было то регстрация прошла успешно
                mod.insertNewUser(req.body.name,req.body.surname,req.body.email,req.body.number,
                    req.body.password).then(function () { // вызов функции добавленя пользователя
                    mod.getUserByEmail(req.body.email).then(function (resultUser) {
                        res.send([{errorCode: 0, user: resultUser}]); // сразу вызов функции получения данных о пользователе
                    })
                });
            }
            else if(phoneCount == 0 && emailCount > 0) // если есть совпадение по email то ошибка о email
                res.send([{errorCode: 1, errorMessage: "Данный Email уже занят"}]);
            else if(phoneCount > 0 && emailCount == 0) // если есть совпадение по телефону то ошибка о телефону
                res.send([{errorCode: 2, errorMessage: "Данный номер телефона уже занят"}]);
            else if(phoneCount > 0 && emailCount > 0) // если есть совпадение по email и телефону то ошибка о email и телефоне
                res.send([{errorCode: 1, errorMessage: "Данный Email уже занят"},
                    {errorCode: 2, errorMessage: "Данный номер телефона уже занят"}]);
        });
    });
});

app.put('/user',function (req, res) {// проверки при изменении пользователя
    let phoneCount = +0,
        emailCount = +0;
    mod.updateUserValidationEmail(req.body.email, req.query.userId).then(function (resultE) {//вызов проверки email
        emailCount = resultE;
        mod.updateUserValidationPhone(req.body.number, req.query.userId).then(function (resultP) {//вызов проверки телефона
            phoneCount = resultP;
            if(phoneCount == 0 && emailCount == 0) { // если совпадений в БД не найдено то обновляем данные о пользователе
                mod.updateUser(req.query.userId,req.body.name,req.body.surname,req.body.number,req.body.email).then(function () {
                    mod.getUserByEmail(req.body.email).then(function (resultUser) { // сразу получаем обновлённые данные
                        res.send([{errorCode: 0, user: resultUser}]); // отправляем данные клиенту
                    })
                });
            }
            else if(phoneCount == 0 && emailCount > 0) // если есть совпадение по email то ошибка о email
                res.send([{errorCode: 1, errorMessage: "Данный Email уже занят"}]);
            else if(phoneCount > 0 && emailCount == 0) // если есть совпадение по телефону то ошибка о телефону
                res.send([{errorCode: 2, errorMessage: "Данный номер телефона уже занят"}]);
            else if(phoneCount > 0 && emailCount > 0) // если есть совпадение по email и телефону то ошибка о email и телефоне
                res.send([{errorCode: 1, errorMessage: "Данный Email уже занят"},
                    {errorCode: 2, errorMessage: "Данный номер телефона уже занят"}]);
        });
    });
});

app.get('/autos',function (req, res) { // получить список автомобилей пользователя
    let userId = req.query.userId,
        free = req.query.free;
    if(free == 'true'){ // получить список только свободных автомобилей пользователя на выбранный промежуток времени
        mod.getCarsFree(userId, req.query.start, req.query.end).then(function(result) {
            res.send(result);
        });
    } else { // получить список всех автомобилей пользователя
        mod.getCarsAll(userId).then(function (result) {
            res.send(result);
        });
    }
});

app.post("/autos", function(req, res){//запрос на добавление авто
    let numberCount = +0,
        userId = req.query.userId,
        number = req.body.number;
    mod.carsCheck(userId,number).then(function (resultE) {//вызов функции проверки уникальности автомобиля
        numberCount = resultE.count;
        if(numberCount == 0) {//если совпадений не найдено то добавляем атомобиль
            mod.insertNewCar(userId,req.body.mark,req.body.model,number).then(function () {//добавиляем машину в БД
                mod.getCarByData(userId, number).then(function (resultCar) {//сразу получаем данные из БД и отправляем клиенту
                    res.send([{errorCode: 0, auto: resultCar}]);
                })
            });
        }
        else if(numberCount > 0) // если есть совпадения то отправить сообщение об ошибке
            res.send([{errorCode: 1, errorMessage: "Данный автомобиль уже зарегистрирован в системе"}]);
    });
});

app.delete('/autos',function (req,res) {//запрос на удаление авто
    let userId = req.query.userId,
        carId = req.query.autoId;
    mod.deleteCar(userId,carId).then(function(result){//вызов метода удаления авто
        res.send([{errorCode: 0}]);
    });
});

app.get('/park', function (req, res) {//запрос на получение схемы парковки
    let Parking = { //json объект который будет содержать в себе данные о схеме парковки
        'width': 0,
        'height': 0,
        'places': []
    };
    mod.getParkingData(parkId).then(function (resultPD) {//запрос на получение высоты ширины парковки
        Parking.width = resultPD[0].width;
        Parking.height = resultPD[0].height;
        mod.getParkingPlacesByDate(parkId,req.query.start,req.query.end).then(function (resultPPD) {//запрос на получение парковочных мест парковки
            resultPPD.forEach(function (element) {//помещаем парковочные места в массив places внутри объекта Parking
                Parking.places.push(element);
            });
            res.send(Parking);//отправляем схему клиенту
        })
    })
});

app.get('/parkXY', function (req, res) {//запрос на получение координат Х и У парковки
    mod.getParkingXY(parkId).then(function (result) {
        res.send({x: result[0].mapx, y: result[0].mapy});
    })
});

app.get('/reservation', function (req, res) {//запрос на получение списка броней
    if(!req.query.userId) // если пользователь не залогинен перенаправить на главную страницу
        res.sendFile(__dirname + "/public/index.html");
    mod.getReservationsById(req.query.userId,parkId).then(function (result) {//получить список броней по Id пользователя
        let array = []; // массив(список броней в будущем), элементами будут json объектыб 1 объект - 1 бронь
        result.forEach(function (element) {//полученный из БД список броней помещаем в array
            let item = {
                'id': element.id,
                'auto': {mark:element.mark, model:element.model, number:element.number}, // json объект внутри json объекта
                'date1': dateFormat(element.date1 - 3*1000*60*60,"dd-mm-yyyy HH:MM"), // преобразование даты в привычный нам формат
                'date2': dateFormat(element.date2 - 3*1000*60*60,"dd-mm-yyyy HH:MM"), // преобразование даты в привычный нам формат
                'placeId': element.placeId,
                'price': element.price};
            array.push(item); // помещение брони в массив
        });
        res.send(array);
    })
});

app.post("/reservation", function(req, res){//запрос на добавление брони
    let autoId = req.body.autoId,
        start = req.body.start, end = req.body.end,
        placeId = req.body.placeId, price = req.body.price;
    mod.insertNewRes(autoId,start,end,placeId,price).then(function (resultNewRes) {//вызов функции добавление брони
        if(resultNewRes == 'Ошибка добавления'){ // там есть условия добавления, возврат сообщения об ошибке в случае их невыполнения
            res.send(resultNewRes)
        } else {
            mod.getResByData(autoId, start, end).then(function (resultRes) {//получение добавленной брони
                let item = { // json объект представляющий собой бронь
                    'id': resultRes.id,
                    'auto': {mark:resultRes.mark, model:resultRes.model, number:resultRes.number},// json объект внутри json объекта
                    'date1': dateFormat(resultRes.arrivalDate - 3*1000*60*60,"dd-mm-yyyy HH:MM"),// преобразование даты в привычный нам формат
                    'date2': dateFormat(resultRes.departureDate - 3*1000*60*60,"dd-mm-yyyy HH:MM"),// преобразование даты в привычный нам формат
                    'placeId': resultRes.parkingPlaceId,
                    'price': resultRes.price};
                res.send(item);//отправка брони клиенту
            })
        }
    });
});

app.delete('/reservation', function (req, res) {//запрос на удаление брони
    let resId = req.query.reservationId;
    mod.deleteRes(resId).then(function(){//вызов метода удаления брони
        res.send([{errorCode: 0}]);
    });
});

app.get('/price', function (req, res) {//запрос на получение цены за минуту на парковке
    mod.getPrice(parkId).then(function (result) { // вызов метода получения цены по Id парковки
        res.send({price: result[0].price});
    })
});

app.get("/*", function(req, res){
    res.sendFile(__dirname + "/public/index.html");
});