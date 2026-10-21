package org.formation.coffee.adapter.out.transaction;

import org.formation.coffee.application.port.out.TransactionRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.function.Supplier;

@Component
class SpringTransactionRunner implements TransactionRunner {

    private final TransactionTemplate readWrite;
    private final TransactionTemplate readOnly;

    SpringTransactionRunner(PlatformTransactionManager transactionManager) {
        this.readWrite = new TransactionTemplate(transactionManager);
        this.readOnly = new TransactionTemplate(transactionManager);
        this.readOnly.setReadOnly(true);
    }

    @Override
    public <T> T execute(Supplier<T> work) {
        return readWrite.execute(status -> work.get());
    }

    @Override
    public <T> T executeReadOnly(Supplier<T> work) {
        return readOnly.execute(status -> work.get());
    }
}
