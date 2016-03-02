require "dry-validation"
require "pp"

RSpec.describe "Form validation" do
  subject(:schema) {
    Class.new(Dry::Validation::Schema) do
      key(:title) { |title| title.filled? }
      key(:rating) { |rating| rating.gteq?(1) & rating.lteq?(10) }

      key(:reviews) do |reviews|
        reviews.filled? & \
        reviews.each do |review|
          review.key(:summary) { |summary| summary.filled? }
          review.key(:rating) { |rating| rating.gteq?(1) & rating.lteq?(10) }
        end

      end

      # TODO: uncomment/fix the "meta" related sections (here and below) once
      # we have a clarification on dryrb/dry-validation#58.
      #
      # key(:meta) do |meta|
      #   meta.key(:pages) { |pages| pages.filled? }
      # end
    end.new
  }

  subject(:form) {
    Class.new(Formalist::Form) do
      field :title, type: "string"
      field :rating, type: "int"

      many :reviews do |review|
        review.field :summary, type: "string"
        review.field :rating, type: "int"
      end

      # attr :meta do |meta|
      #   meta.field :pages, type: "int"
      # end
    end.new(schema)
  }

  it "includes validation rules and errors in the AST" do
    input = {
      reviews: [{summary: "Great", rating: 0}, {summary: "", rating: 1}],
      meta: {pages: nil}
    }

    expect(form.build(schema.(input)).to_ast).to eq [
      [:field, [:title, :field, nil, [[:predicate, [:filled?, []]]], ["title is missing"], []]],
      [:field, [:rating, :field, nil, [[:and, [[:predicate, [:gteq?, [1]]], [:predicate, [:lteq?, [10]]]]]], ["rating is missing", "rating must be greater than or equal to 1", "rating must be less than or equal to 10"], []]],
      [:many, [
        :reviews,
        :many,
        [[:predicate, [:filled?, []]]],
        [],
        [
          [:allow_create, true],
          [:allow_update, true],
          [:allow_destroy, true],
          [:allow_reorder, true],
        ],
        [
          [:field, [:summary, :field, nil, [[:predicate, [:filled?, []]]], [], []]],
          [:field, [:rating, :field, nil, [[:and, [[:predicate, [:gteq?, [1]]], [:predicate, [:lteq?, [10]]]]]], [], []]],
        ],
        [
          [
            [:field, [:summary, :field, "Great", [[:predicate, [:filled?, []]]], [], []]],
            [:field, [:rating, :field, 0, [[:and, [[:predicate, [:gteq?, [1]]], [:predicate, [:lteq?, [10]]]]]], ["rating must be greater than or equal to 1"], []]],
          ],
          [
            [:field, [:summary, :field, "", [[:predicate, [:filled?, []]]], ["summary must be filled"], []]],
            [:field, [:rating, :field, 1, [[:and, [[:predicate, [:gteq?, [1]]], [:predicate, [:lteq?, [10]]]]]], [], []]],
          ]
        ],
      ]],
      # [:attr, [:meta,
      #   [],
      #   [],
      #   [
      #     [:field, [:pages, "int", "default", nil, [[:predicate, [:filled?, []]]], ["pages must be filled"], []]]
      #   ],
      # ]]
    ]
  end
end
