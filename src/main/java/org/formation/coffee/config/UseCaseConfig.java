package org.formation.coffee.config;

import org.formation.coffee.application.port.out.LoadCoffeePort;
import org.formation.coffee.application.port.out.SaveCoffeePort;
import org.formation.coffee.application.port.out.TransactionRunner;
import org.formation.coffee.application.service.CoffeeApplicationService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Branche les services applicatifs, écrits sans framework, dans le contexte Spring.
 */
@Configuration(proxyBeanMethods = false)
class UseCaseConfig {

    @Bean
    CoffeeApplicationService coffeeApplicationService(LoadCoffeePort loadCoffeePort,
                                                      SaveCoffeePort saveCoffeePort,
                                                      TransactionRunner transactionRunner) {
        return new CoffeeApplicationService(loadCoffeePort, saveCoffeePort, transactionRunner);
    }
}
