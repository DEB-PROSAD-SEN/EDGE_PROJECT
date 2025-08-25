%% 🌍 CO₂ Emissions Analysis Project - MATLAB Version
% Dataset: Our World in Data (owid-co2-data.csv)

clear; clc; close all;

%% 1. Load Dataset
data = readtable("owid-co2-data.csv");

% Keep only countries (ISO-3 codes, not OWID aggregates)
data = data(~ismissing(data.iso_code), :);
isCountry = strlength(string(data.iso_code)) == 3 & ~startsWith(string(data.iso_code),"OWID");
countries = data(isCountry,:);

latestYear = max(countries.year);

%% 2. CO₂ Intensity (CO₂ per GDP)
countries.co2_intensity = countries.co2 ./ countries.gdp;

intensity = groupsummary(countries,"year","mean","co2_intensity");

figure;
plot(intensity.year, intensity.mean_co2_intensity,'LineWidth',2,'Color','r');
xlabel("Year"); ylabel("CO₂ Intensity (t CO₂ / $ GDP)");
title("Global CO₂ Intensity Over Time");
grid on;

%% 3. Cumulative CO₂ (Historical Responsibility)
cumulative = groupsummary(countries,"country","max","cumulative_co2");
[~,idx] = maxk(cumulative.max_cumulative_co2,10);
topCumulative = cumulative(idx,:);

figure;
barh(categorical(topCumulative.country), topCumulative.max_cumulative_co2);
xlabel("Cumulative CO₂ (million tonnes)");
ylabel("Country");
title("Top 10 Countries by Historical CO₂ Emissions");

%% 4. Growth Rate in CO₂ Emissions
countries = sortrows(countries,["country","year"]);
countries.co2_growth = [NaN; diff(countries.co2)]./countries.co2 * 100;

% Group global average growth per year
growth = groupsummary(countries,"year","mean","co2_growth");

figure;
plot(growth.year, growth.mean_co2_growth,'b','LineWidth',1.5);
hold on; yline(0,'--k');
xlabel("Year"); ylabel("Growth Rate (%)");
title("Average Global Growth Rate of CO₂ Emissions");
grid on;

%% 5. CO₂ vs Life Expectancy (Scatter, latest year)
if any(strcmp("life_expectancy", countries.Properties.VariableNames))
    subset = countries(countries.year == latestYear,:);
    valid = ~isnan(subset.life_expectancy) & ~isnan(subset.co2_per_capita);

    figure;
    scatter(subset.co2_per_capita(valid), subset.life_expectancy(valid), ...
        sqrt(subset.population(valid))/1e3, 'filled','MarkerFaceAlpha',0.5);
    xlabel("CO₂ per Capita (tonnes)");
    ylabel("Life Expectancy (years)");
    title("CO₂ per Capita vs Life Expectancy");
    grid on;
end

%% 6. Animated Scatter (GDP vs CO₂ per Capita over Time)
% Only from 1950 onwards
animData = countries(countries.year >= 1950,:);
valid = ~isnan(animData.gdp) & ~isnan(animData.co2_per_capita);

animData = animData(valid,:);

figure;
ax = gca;
xlabel("GDP (Billion USD, log scale)");
ylabel("CO₂ per Capita (tonnes)");
title("GDP vs CO₂ per Capita (1950–Present)");
ax.XScale = 'log';
hold on;

years = unique(animData.year);
colors = lines(10); % for variety

for i = 1:length(years)
    yr = years(i);
    subset = animData(animData.year == yr,:);
    scatter(subset.gdp/1e9, subset.co2_per_capita, ...
        sqrt(subset.population)/1e6, 'filled','MarkerFaceAlpha',0.5);
    xlabel("GDP (Billion USD, log scale)");
    ylabel("CO₂ per Capita (tonnes)");
    title(["GDP vs CO₂ per Capita", num2str(yr)]);
    drawnow;
    pause(0.1);
    if i < length(years)
        cla; % clear for next frame
    end
end
