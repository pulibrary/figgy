1. Ensure the rabbitmq message queue is empty. You can ssh tunnel to the console UI. figgy1 is the rabbitm1 host. Get the login credentials from the ansible vault. this documentation is also helpful: https://www.rabbitmq.com/management.html#usage-ui.
2. Change the slug in dpul via the console. Spotlight::Exhibit is an active record model.
3. Change the slug in figgy via the web form. Note: Changing the title would require a reindex on the dpul collection.
4. Reindex the DPUL collection via UI (solr documents use the collection slug as a prefix for fields)