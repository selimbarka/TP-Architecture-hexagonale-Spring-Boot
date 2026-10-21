package org.formation.coffee.adapter.in.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.formation.coffee.adapter.in.web.dto.CoffeeResponse;
import org.formation.coffee.adapter.in.web.dto.CreateCoffeeRequest;
import org.formation.coffee.adapter.in.web.dto.UpdateCoffeeRequest;
import org.formation.coffee.application.port.in.CreateCoffeeUseCase;
import org.formation.coffee.application.port.in.GetCoffeeQuery;
import org.formation.coffee.application.port.in.ListCoffeesQuery;
import org.formation.coffee.application.port.in.UpdateCoffeeUseCase;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping(path = "/api/coffees", version = "1")
@Tag(name = "Coffees", description = "Coffee catalog")
class CoffeeController {

    private final ListCoffeesQuery listCoffeesQuery;
    private final GetCoffeeQuery getCoffeeQuery;
    private final CreateCoffeeUseCase createCoffeeUseCase;
    private final UpdateCoffeeUseCase updateCoffeeUseCase;
    private final CoffeeWebMapper mapper;

    CoffeeController(ListCoffeesQuery listCoffeesQuery,
                     GetCoffeeQuery getCoffeeQuery,
                     CreateCoffeeUseCase createCoffeeUseCase,
                     UpdateCoffeeUseCase updateCoffeeUseCase,
                     CoffeeWebMapper mapper) {
        this.listCoffeesQuery = listCoffeesQuery;
        this.getCoffeeQuery = getCoffeeQuery;
        this.createCoffeeUseCase = createCoffeeUseCase;
        this.updateCoffeeUseCase = updateCoffeeUseCase;
        this.mapper = mapper;
    }

    @GetMapping
    @Operation(summary = "List all coffees with their reviews")
    List<CoffeeResponse> listCoffees() {
        return listCoffeesQuery.listCoffees().stream().map(mapper::toResponse).toList();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a coffee by its id")
    CoffeeResponse getCoffee(@PathVariable long id) {
        return mapper.toResponse(getCoffeeQuery.getCoffee(new CoffeeId(id)));
    }

    @PostMapping
    @Operation(summary = "Create a coffee")
    ResponseEntity<CoffeeResponse> createCoffee(@Valid @RequestBody CreateCoffeeRequest request,
                                                UriComponentsBuilder uriBuilder) {
        Coffee created = createCoffeeUseCase.createCoffee(mapper.toCommand(request));
        CoffeeResponse response = mapper.toResponse(created);
        URI location = uriBuilder.path("/api/coffees/{id}").buildAndExpand(response.id()).toUri();
        return ResponseEntity.created(location).body(response);
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Partially update a coffee")
    CoffeeResponse updateCoffee(@PathVariable long id, @Valid @RequestBody UpdateCoffeeRequest request) {
        return mapper.toResponse(updateCoffeeUseCase.updateCoffee(mapper.toCommand(id, request)));
    }
}
