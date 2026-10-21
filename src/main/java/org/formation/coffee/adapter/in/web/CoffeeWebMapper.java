package org.formation.coffee.adapter.in.web;

import org.formation.coffee.adapter.in.web.dto.CoffeeResponse;
import org.formation.coffee.adapter.in.web.dto.CreateCoffeeRequest;
import org.formation.coffee.adapter.in.web.dto.ReviewResponse;
import org.formation.coffee.adapter.in.web.dto.UpdateCoffeeRequest;
import org.formation.coffee.application.port.in.CreateCoffeeCommand;
import org.formation.coffee.application.port.in.UpdateCoffeeCommand;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.formation.coffee.domain.model.Price;
import org.formation.coffee.domain.model.Review;
import org.formation.coffee.domain.model.ReviewId;
import org.jspecify.annotations.Nullable;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper
interface CoffeeWebMapper {

    CoffeeResponse toResponse(Coffee coffee);

    ReviewResponse toReviewResponse(Review review);

    CreateCoffeeCommand toCommand(CreateCoffeeRequest request);

    @Mapping(target = "id", source = "id")
    @Mapping(target = "name", source = "request.name")
    @Mapping(target = "price", source = "request.price")
    UpdateCoffeeCommand toCommand(long id, UpdateCoffeeRequest request);

    default long toValue(CoffeeId id) {
        return id.value();
    }

    default long toValue(ReviewId id) {
        return id.value();
    }

    default int toAmount(Price price) {
        return price.amount();
    }

    default CoffeeId toCoffeeId(long id) {
        return new CoffeeId(id);
    }

    default @Nullable Price toPrice(@Nullable Integer amount) {
        return amount == null ? null : new Price(amount);
    }
}
