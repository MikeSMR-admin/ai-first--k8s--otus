Создать группу узлов
Эта статья полезна?


Для каждого кластера можно создать несколько групп узлов.


Личный кабинет

API

Terraform
Пройдите аутентификацию в API.

Выполните HTTP-запрос:


POST https://mk8s.api.cloud.ru/v3/nodePools

В теле запроса передайте следующие параметры:


{
  "clusterId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "name": "cloudru-example-nodepool",
  "scalePolicy": {
    "fixedScale": {
     "count": 1
    }
  },
  "machineConfiguration": {
    "flavorId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
    "disk": {
      "typeName": "SSD",
      "size": 30
    }
  },
  "networkConfiguration": {
    "nodesSubnetId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  },
  "updateConfiguration": {
    "strategy": "NODE_POOL_UPDATE_STRATEGY_ROLLING_UPDATE"
  }
}

Где:

clusterId — идентификатор кластера.

name — название группы узлов.

Должно быть уникальным.

Может содержать буквы, цифры, пробелы, подчеркивания и дефисы.

Допустимое количество символов — от 4 до 60.

scalePolicy.fixedScale.count — количество узлов.

Как настроить автомасштабирование для группы узлов, читайте в сценарии Настройка автомасштабирования группы узлов.

machineConfiguration.flavorId — идентификатор шаблона конфигурации узлов. Узнать список всех конфигураций.

machineConfiguration.disk.typeName — тип диска.

machineConfiguration.disk.size — объем хранилища в ГБ. Целое число от 10 до 16 384.

networkConfiguration.nodesSubnetId — идентификатор подсети в формате <адрес сети>/<префикс маски>, из которой для узлов будут назначаться IP-адреса.

Подсеть должна принадлежать диапазонам 10.0.0.0/20–28, 172.16.0.0/20–28 или 192.168.0.0/20–28 и не может пересекаться с другими подсетями созданной инфраструктуры. Размер подсети узлов должен быть в два раза меньше размера подсети сервисов.

Где посмотреть идентификатор, читайте в инструкции Посмотреть параметры подсети.

updateConfiguration.strategy — стратегия обновления группы узлов.

Подробное описание параметров читайте в справочнике API.