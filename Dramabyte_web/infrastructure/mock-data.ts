import { HomeFeed, SeriesCard } from "@/domain/models";

const covers = [
  ["The Last Seat", "Mystery", "A silent tear, a hidden truth, and one seat that changes everything."],
  ["The Last Train Home", "Drama", "One final train. One impossible promise. No way back."],
  ["A Contracted Heart", "Romance", "Their deal was simple until pretending became real."],
  ["The Heiress Returns", "Revenge", "She lost her name. Now she is coming back for the truth."],
  ["Midnight Vows", "Romance", "A forbidden vow binds two rival families together."],
  ["After the Bell", "Teen Drama", "At Westbridge, every secret has an audience."],
];

export const mockSeries: SeriesCard[] = covers.map(([title, genre, description], index) => ({
  series_id: `demo-${index + 1}`,
  title,
  genre,
  description,
  episode_count: 15 + index * 4,
  free_episode_count: 3,
  thumbnail_url: "",
}));

export const mockHome: HomeFeed = {
  featured: mockSeries.slice(0, 3),
  trending: mockSeries.slice(0, 5),
  genres: [
    { genre: "New releases", items: mockSeries.slice(1) },
    { genre: "Romance", items: mockSeries.filter((item) => item.genre === "Romance") },
  ],
};
