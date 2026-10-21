package org.formation.coffee.adapter.in.web.dto;

import java.util.List;

public record CoffeeResponse(long id, String name, int price, List<ReviewResponse> reviews) {
}
