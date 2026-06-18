Создать кластер
Эта статья полезна?


В инструкции описано, как создать кластер Kubernetes в личном кабинете, с помощью API-запроса или Terraform. В проекте можно создать один или несколько кластеров в пределах запрошенных вычислительных ресурсов. Если ресурсов не хватает, отправьте заявку на увеличение квоты.


Личный кабинет

API

Terraform
Пройдите аутентификацию в API.

Выполните HTTP-запрос:


POST https://mk8s.api.cloud.ru/v3/clusters

В теле запроса передайте следующие параметры:


{
  "name": "cloudru-example-cluster",
  "projectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx",
  "controlPlaneConfiguration": {
     "version": "v1.34.1",
     "sizingConfiguration": {
        "masterCount": 1,
        "flavorId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx"
     }
   },
  "networkConfiguration": {
     "servicesSubnetCidr": "10.96.0.0/12",
     "podsSubnetCidr": "10.1.0.0/16",
     "kubeApiInternet": true,
     "privateVipSubnetId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx"
   }
}

Где:

projectId — идентификатор проекта.

name — название кластера.

Должно быть уникальным.

Может содержать буквы, цифры, пробелы, подчеркивания и дефисы.

Допустимое количество символов — от 3 до 60.

controlPlaneConfiguration — конфигурация плоскости управления кластера.

controlPlaneConfiguration.version — версия Kubernetes в формате SemVer.

controlPlaneConfiguration.sizingConfiguration — конфигурация размерности плоскости управления кластера и мастер-узлов.

controlPlaneConfiguration.sizingConfiguration.masterCount — количество мастер-узлов.

controlPlaneConfiguration.sizingConfiguration.flavorId — идентификатор конфигурации мастер-узлов.

networkConfiguration — сетевая конфигурация кластера и плоскости управления.

networkConfiguration.servicesSubnetCidr — подсеть в формате <адрес сети>/<префикс маски>. IP-адреса для сервисов кластера будут назначаться из этой подсети.

Подсеть должна принадлежать диапазонам 10.0.0.0/12–28, 172.16.0.0/12–28 или 192.168.0.0/16–28 и не может пересекаться с другими подсетями созданной инфраструктуры.

networkConfiguration.podsSubnetCidr — подсеть в формате <адрес сети>/<префикс маски>. IP-адреса для подов будут назначаться из этой подсети.

Подсеть должна принадлежать диапазонам 10.0.0.0/8–24, 172.16.0.0/12–24 или 192.168.0.0/16–24 и не может пересекаться с другими подсетями созданной инфраструктуры.

networkConfiguration.kubeApiInternet — параметр доступности kube-apiserver по внешнему IP-адресу. Если значение true, к API-серверу можно будет обратиться из сети интернет по публичному IP. Адрес назначается автоматически.

networkConfiguration.privateVipSubnetId — идентификатор подсети, из которой необходимо выделить внутренний IP-адрес.

Создание кластера занимает 5–10 минут. Для продолжения работы убедитесь, что состояние кластера — «Запущено».