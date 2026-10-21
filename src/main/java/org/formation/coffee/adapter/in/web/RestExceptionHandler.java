package org.formation.coffee.adapter.in.web;

import org.formation.coffee.domain.exception.CoffeeNotFoundException;
import org.formation.coffee.domain.exception.DomainValidationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Traduit les exceptions du domaine en problem details RFC 9457.
 * Les exceptions du framework (validation, JSON invalide) sont déjà gérées par Spring Boot.
 */
@RestControllerAdvice
class RestExceptionHandler {

    @ExceptionHandler
    ProblemDetail handleNotFound(CoffeeNotFoundException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, exception.getMessage());
        problem.setTitle("Coffee not found");
        problem.setProperty("coffeeId", exception.getCoffeeId().value());
        return problem;
    }

    @ExceptionHandler
    ProblemDetail handleValidation(DomainValidationException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.UNPROCESSABLE_CONTENT, exception.getMessage());
        problem.setTitle("Business rule violated");
        return problem;
    }
}
