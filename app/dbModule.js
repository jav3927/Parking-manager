const sql = require('mssql');//подключение модуля для работы с MsSQL
const config = { //конфиг БД
	user: 'user1',
	password: '12345',
	server: 'localhost',
	database: 'Parking',
	port: 1433
};
//User block - тут будут все запросы связанные с пользователем
module.exports.registrationValidationPhone = async function(phone) {//запрос на проверку уникальности телефона при регистрации
	return new Promise(function(resolve, reject) {// говорим что функция будет возвращать Promise
		sql.connect(config).then(function() {//проиизводим подключение к БД по конфигу, после подключения будет функция(then)
			let usQueryL = `select count(*) as phoneCount from Users where userPhone = '${phone}'`;//запрос на получение количества таких телефонов в БД
			let objL = new sql.Request().query(usQueryL).then(function(result) {//выполнение запроса, резульатт будет в переменной result
				resolve(result.recordset[0].phoneCount);//resolve - отправить результат промиса
			}).catch(function(err) {//result.recordset[0].phoneCount result - результат запроса, recordset это объекты полученные в результате запроса phoneCount в данном случае название поля из результирующей таблицы
				console.dir(err);//в случае ошибки выведется в консоль
			});
		}).catch(function(err) {
			console.dir(err);//в случае ошибки выведется в консоль
		});
	})
};

module.exports.registrationValidationEmail = async function(email) {//запрос на проверку уникальности email при регистрации
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQueryE = `select count(*) as emailCount from Users where email = '${email}'`,
				emailCount = +0;
			let objE = new sql.Request().query(usQueryE).then(function(result) {
				resolve(result.recordset[0].emailCount);
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.LogInValidation = async function(login, password, type) {//запрос на проверку корректности данных при логине
	return new Promise(function(resolve, reject) {
	    sql.connect(config).then(function() {
	        console.log(type);
			let usQuery = `select * from LogInValidation('${login}','${password}','${type}')`;//type - это для запроса, вход будет по телефону или email
			let obj = new sql.Request().query(usQuery).then(function(result) {
			    console.log(result);
				resolve(result.recordset[0]);
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
}; //++

module.exports.insertNewUser = async function(username, surname, email, userphone, password) {//запрос на добавление нового пользователя
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `insert into Users values(newId(),'${username}','${surname}','${email}','${userphone}','${password}')`;
			let obj = new sql.Request().query(usQuery).then(function() {
				resolve("Клиент успешно добавлен.");
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.getUserByEmail = async function(email) {//запрос на получение данных о пользователе по email
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from getUserByEmail('${email}')`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset[0]);
			}).catch(function (err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.updateUser = async function(userId, username, surname, userphone, email) {//запрос на изменение данных о пользователе
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `exec userUpdate '${userId}','${username}',${surname},'${userphone}','${email}'`;
			let obj = new sql.Request().query(usQuery).then(function() {
				resolve("Данные успешно обновлены/добавлены.");
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.updateUserValidationPhone = async function(phone,userId) {//запрос на проверку данных при изменений данных о пользователе
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQueryL = `select count(*) as phoneCount from Users where userPhone = '${phone}' and Id !='${userId}'`;
			let objL = new sql.Request().query(usQueryL).then(function(result) {
				resolve(result.recordset[0].phoneCount);
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.updateUserValidationEmail = async function(email,userId) {//запрос на проверку данных при изменений данных о пользователе
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQueryE = `select count(*) as emailCount from Users where email = '${email}' and Id !='${userId}'`,
				emailCount = +0;
			let objE = new sql.Request().query(usQueryE).then(function(result) {
				resolve(result.recordset[0].emailCount);
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};
//User block
//Car block тут будут все запросы связанные с машинами
module.exports.carsCheck = async function(userId, number) {//запрос на проверку существования автомобиля в БД
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `select dbo.CarInsertValidation('${userId}','${number}') as count`;
			let obj = new sql.Request().query(usQuery).then(function(result) {
				resolve(result.recordset[0]);
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
}; //++

module.exports.insertNewCar = async function(userId,mark,model,number) {//запрос на добавление нового авто в БД
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `insert into Cars values(newId(),'${userId}','${mark}','${model}','${number}')`;
			let obj = new sql.Request().query(usQuery).then(function() {
				resolve("Машина успешно добавлена.");
			}).catch(function(err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.getCarByData = async function(userId, number) {//запрос на получение данных об авто из БД
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from Cars where userId = '${userId}' and number = '${number}'`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset[0]);
			}).catch(function (err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.getCarsAll = async function(userId) {//запрос на получение полного списка авто определённого пользователя
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from getCarsAll('${userId}') order by mark, model, number`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.getCarsFree = async function(userId, start, end) {//запрос на получение списка свободных авто в определённый промежуток времени
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from getCarsFree('${userId}','${start}','${end}') order by mark, model, number`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.deleteCar = async function(userId, carId) {//запрос на удаление автомобиля из БД
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `delete from Cars where userId = '${userId}' and Id = '${carId}'`;
			let obj = new sql.Request().query(usQuery).then(function() {
				resolve("Данные успешно удалены.");
			}).catch(function(err) {
				console.dir(err);
				reject(err);
			});
		}).catch(function(err) {
			console.dir(err);
			reject(err);
		});
	})
};
//Car block
//Parking block тут будут все запросы связанные с парковкой
module.exports.getParkingData = async function(parkingId) {//запрос на получение высоты и ширины парковки
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select width, height from Parking where Id = '${parkingId}'`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.getParkingPlacesByDate = async function(parkingId, beginDate, endDate) {//запрос на получение данных о парковке в определённый промежутко времени
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from getParkingPlacesByDate('${parkingId}','${beginDate}','${endDate}') order by number`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.getParkingPlacesById = async function(parkingId) {//запрос на получение парковочных мест определённой парковки
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from ParkingPlaces where ParkingId = '${parkingId}' order by number`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.getParkingXY = async function(parkingId) {//запрос на получение координат Х и У определённой парковки
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select mapx, mapy from Parking where Id = '${parkingId}'`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.getPrice = async function(parkingId) {//запрос на получение цены за минуту определённой парковки
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select price from PriceList where parkingId = '${parkingId}'`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};
//Parking block
//Reservation block тут будут все запросы связанные с бронями
module.exports.getReservationsById = async function(userId, parkingId) {//запрос на получение броней определённого пользователя
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select * from getReservationsById('${userId}','${parkingId}')`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset);
			}).catch(function(err) {
				console.dir(err);
			});
		})
	})
};

module.exports.insertNewRes = async function(carId,start,end,placeId,price) {//запрос на добавление брони
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `insert into Books values(newId(),'${carId}','${placeId}','${start}','${end}',${price})`;
			let obj = new sql.Request().query(usQuery).then(function() {
				resolve("Бронирование места прошло успешно.");
			}).catch(function(err) {
				reject('Ошибка добавления');
			});
		}).catch(function(err) {
			reject('Ошибка добавления');
		});
	})
};

module.exports.getResByData = async function(carId,start,end) {//запрос на получение данных о брони
	return new Promise(function(resolve, reject) {
		let usQuery;
		sql.connect(config).then(function() {
			usQuery = `select Books.id,Cars.mark,Cars.model,Cars.number,arrivalDate,departureDate,parkingPlaceId,price 
						from Books inner join Cars on Books.carId = Cars.Id where carId = '${carId}' and 
						arrivalDate = '${start}' and departureDate = '${end}'`;
			let obj = new sql.Request().query(usQuery).then(function (result) {
				resolve(result.recordset[0]);
			}).catch(function (err) {
				console.dir(err);
			});
		}).catch(function(err) {
			console.dir(err);
		});
	})
};

module.exports.deleteRes = async function(resId) {//запрос на удаление брони
	return new Promise(function(resolve, reject) {
		sql.connect(config).then(function() {
			let usQuery = `delete from Books where id='${resId}'`;
			let obj = new sql.Request().query(usQuery).then(function() {
				resolve("Данные успешно удалены.");
			}).catch(function(err) {
				console.dir(err);
				reject(err);
			});
		}).catch(function(err) {
			console.dir(err);
			reject(err);
		});
	})
};
//Reservation block