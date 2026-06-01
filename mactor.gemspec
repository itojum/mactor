# frozen_string_literal: true

require_relative "lib/mactor/version"

Gem::Specification.new do |spec|
  spec.name = "mactor"
  spec.version = Mactor::VERSION
  spec.authors = ["itojum"]
  spec.email = ["tech@itojum.dev"]

  spec.summary = "Ractor-compatible Markdown parser"
  spec.description = "A Markdown parser built to work safely with Ractor, Ruby's actor-based concurrency model."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"
end
